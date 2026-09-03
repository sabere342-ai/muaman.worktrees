import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

/**
 * Edge Function: s6-device-pop
 *
 * Phase P Group B S6 — dedicated Ed25519 proof-of-possession verifier.
 *
 * Its sole narrow security responsibility is S6 PoP verification. It NEVER
 * enables the device gate, NEVER activates request-bound enforcement, and
 * only records a server-authoritative single-use assertion AFTER it has
 * cryptographically verified an Ed25519 (RFC 8032) signature over the
 * canonical S6 envelope using the server-bound public key.
 *
 * Flow (Governance Section S):
 *   1. authenticate the calling Supabase user (JWT)
 *   2. derive the authoritative user identity from the validated session
 *   3. obtain the challenge record (device_challenges)
 *   4. ensure the challenge belongs to the correct user/shop/device/install
 *   5. ensure the challenge is unused (single-use, server-authoritative)
 *   6. ensure the challenge is not expired
 *   7. obtain the server-bound devices.public_key
 *   8. require the valid/allowed device lifecycle state (ACTIVE)
 *   9. reconstruct the canonical S6 envelope from AUTHORITATIVE server data
 *  10. decode the canonical public key (32 bytes, base64url)
 *  11. decode the signature (64 bytes, base64url)
 *  12. verify Ed25519 via Deno WebCrypto
 *  13. on verification failure -> fail closed (NO assertion recorded)
 *  14. on success -> invoke s4_assert_request (server-authoritative recorder)
 *  15. assertion consumption remains single-use / race-safe
 *  16. return ONLY non-secret result metadata
 *
 * The service-role credential is used internally to read server records and
 * record the assertion; it is NEVER returned to the client and never logged.
 *
 * Request body (minimum identifiers + routing context only):
 *   { "shop_id": <uuid>, "device_id": <uuid>,
 *     "challenge_id": <uuid>, "signature": "<base64url 64-byte>" }
 *
 * The caller-supplied user_id / installation_id / expires_at / challenge /
 * public_key are NOT trusted. Everything except unavoidable routing identity
 * and the signature itself is reconstructed from server records.
 */

// Canonical envelope constants (must EXACTLY match the Dart implementation).
const ENVELOPE_PROTOCOL = "itech-s6-pop"
const ENVELOPE_VERSION = 1
const ENVELOPE_PURPOSE = "device-proof"

/** Base64url without padding -> Uint8Array. Returns null on malformed input. */
function decodeBase64UrlStrict(value) {
  if (!value || value.length === 0) return null
  if (value.includes("=")) return null
  if (/[^A-Za-z0-9_\-]/.test(value)) return null
  try {
    const bin = atob(value.replace(/-/g, "+").replace(/_/g, "/"))
    const bytes = new Uint8Array(bin.length)
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i)
    return bytes
  } catch (_) {
    return null
  }
}

/** Uint8Array -> base64url without padding. */
function encodeBase64UrlNoPadding(bytes) {
  let bin = ""
  bytes.forEach((b) => (bin += String.fromCharCode(b)))
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")
}

/**
 * Format a Date as canonical RFC3339 UTC (seconds precision, 'Z' suffix),
 * byte-identical to PostgreSQL to_char(...,'YYYY-MM-DD"T"HH24:MI:SS"Z"').
 */
function canonicalExpiresAt(date) {
  const pad = (n) => String(n).padStart(2, "0")
  return `${date.getUTCFullYear()}-${pad(date.getUTCMonth() + 1)}-${pad(date.getUTCDate())}T${pad(date.getUTCHours())}:${pad(date.getUTCMinutes())}:${pad(date.getUTCSeconds())}Z`
}

/**
 * Reconstruct the canonical S6 envelope UTF-8 bytes from authoritative server
 * values. Key order is FIXED. No insignificant whitespace. Values are UUID /
 * RFC3339 / simple strings — no JSON escaping needed, so this literal
 * construction is byte-identical to the Dart implementation.
 */
function canonicalEnvelopeBytes({
  challengeId,
  challenge,
  shopId,
  deviceId,
  userId,
  installationId,
  expiresAt,
}) {
  const s =
    `{"protocol":"${ENVELOPE_PROTOCOL}","version":${ENVELOPE_VERSION},` +
    `"challenge_id":"${challengeId}","challenge":"${challenge}",` +
    `"shop_id":"${shopId}","device_id":"${deviceId}","user_id":"${userId}",` +
    `"installation_id":"${installationId}","expires_at":"${expiresAt}",` +
    `"purpose":"${ENVELOPE_PURPOSE}"}`
  return new TextEncoder().encode(s)
}

/** Verify an Ed25519 signature via Deno WebCrypto. */
async function verifyEd25519(publicKeyBytes, signatureBytes, messageBytes) {
  const key = await crypto.subtle.importKey(
    "raw",
    publicKeyBytes,
    { name: "Ed25519" },
    false,
    ["verify"]
  )
  return crypto.subtle.verify("Ed25519", key, signatureBytes, messageBytes)
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ success: false, error: "Method not allowed" }),
      { status: 405, headers: { "Content-Type": "application/json" } }
    )
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: "Authentication required" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      )
    }

    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    )

    // 1. Authenticate the calling Supabase user.
    const { data: { user }, error: authError } = await supabaseUser.auth.getUser()
    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid authentication" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      )
    }
    // 2. Authoritative user identity comes from the validated JWT.
    const userId = user.id

    const body = await req.json()
    const { shop_id, device_id, challenge_id, signature } = body
    if (!shop_id || !device_id || !challenge_id || !signature) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing required fields: shop_id, device_id, challenge_id, signature" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // 3. Obtain the authoritative challenge record.
    const { data: challenge, error: challengeError } = await supabaseAdmin
      .from("device_challenges")
      .select("id, shop_id, device_id, challenge, expires_at, used_at")
      .eq("id", challenge_id)
      .single()

    if (challengeError || !challenge) {
      return new Response(
        JSON.stringify({ success: false, error: "Unknown challenge" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // 4a. Challenge must belong to the caller's shop/device (fail closed).
    if (challenge.shop_id !== shop_id || challenge.device_id !== device_id) {
      return new Response(
        JSON.stringify({ success: false, error: "Challenge routing mismatch" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // 4b. Challenge must have been created for THIS user / device / install.
    const { data: device, error: deviceError } = await supabaseAdmin
      .from("devices")
      .select("id, shop_id, user_id, installation_id, status, public_key")
      .eq("id", device_id)
      .eq("shop_id", shop_id)
      .single()

    if (deviceError || !device) {
      return new Response(
        JSON.stringify({ success: false, error: "Unknown device" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }
    if (device.user_id !== userId) {
      return new Response(
        JSON.stringify({ success: false, error: "Cross-user proof denied" }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      )
    }
    const installationId = device.installation_id

    // 5. Single-use: challenge must not already be consumed.
    if (challenge.used_at) {
      return new Response(
        JSON.stringify({ success: false, error: "Challenge already consumed" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // 6. Not expired (server-authoritative; client clock cannot extend).
    if (!challenge.expires_at || new Date(challenge.expires_at).getTime() <= Date.now()) {
      return new Response(
        JSON.stringify({ success: false, error: "Challenge expired" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // 7. Server-bound public key must exist.
    if (!device.public_key) {
      return new Response(
        JSON.stringify({ success: false, error: "Device has no bound public key" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // 8. Allowed lifecycle state: proof is only accepted for an APPROVED device.
    if (device.status !== "ACTIVE") {
      return new Response(
        JSON.stringify({ success: false, error: "Device is not approved" }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      )
    }

    // 10/11. Decode canonical public key and signature (reject malformed).
    const publicKeyBytes = decodeBase64UrlStrict(device.public_key)
    const signatureBytes = decodeBase64UrlStrict(signature)
    if (!publicKeyBytes || publicKeyBytes.length !== 32) {
      return new Response(
        JSON.stringify({ success: false, error: "Malformed public key" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }
    if (!signatureBytes || signatureBytes.length !== 64) {
      return new Response(
        JSON.stringify({ success: false, error: "Malformed signature" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // 9. Reconstruct canonical envelope from AUTHORITATIVE server data.
    // The caller-supplied user/install/expires/challenge are NOT trusted.
    const messageBytes = canonicalEnvelopeBytes({
      challengeId: challenge.id,
      challenge: challenge.challenge,
      shopId: challenge.shop_id,
      deviceId: challenge.device_id,
      userId: userId,
      installationId: installationId,
      expiresAt: canonicalExpiresAt(new Date(challenge.expires_at)),
    })

    // 12. Verify Ed25519 via Deno WebCrypto.
    let valid
    try {
      valid = await verifyEd25519(publicKeyBytes, signatureBytes, messageBytes)
    } catch (_) {
      valid = false
    }
    if (!valid) {
      // 13. Fail closed: a verification failure must NEVER create an assertion.
      return new Response(
        JSON.stringify({ success: false, error: "Signature verification failed" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      )
    }

    // 14. Signature verified -> invoke the server-authoritative assertion
    // recorder. s4_assert_request consumes the challenge single-use (FOR
    // UPDATE + used_at guard) so concurrent replays fail. It requires device
    // ACTIVE and rejects replay/expiry.
    const { data: asserted, error: assertError } = await supabaseAdmin.rpc(
      "s4_assert_request",
      {
        p_challenge_id: challenge_id,
        p_signature: signature,
        p_signature_format: "ed25519",
      }
    )

    if (assertError || asserted !== true) {
      return new Response(
        JSON.stringify({ success: false, error: assertError?.message || "Assertion recording failed" }),
        { status: 409, headers: { "Content-Type": "application/json" } }
      )
    }

    // 16. Return only non-secret result metadata.
    return new Response(
      JSON.stringify({ success: true, challenge_id, device_id, shop_id }),
      { headers: { "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message || "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
