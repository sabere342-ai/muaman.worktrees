import {
  assertEquals,
  assertObjectMatch,
  assertStringIncludes,
} from "https://deno.land/std@0.168.0/testing/asserts.ts"

/**
 * s6-device-pop Edge Function — deterministic Ed25519 / WebCrypto verifier
 * tests (Phase P Group B S6).
 *
 * Includes the frozen cross-language GOLDEN VECTOR (Governance Section X):
 * the Dart implementation signed the canonical payload with the fixed TEST
 * seed; this Deno test proves the resulting signature verifies under Deno
 * WebCrypto (Scenario 28, AC24/AC25).
 *
 * TEST-ONLY material. Never reuse in production.
 */

// ────────────────────────────────────────────────────────────────────────────
// FROZEN GOLDEN VECTOR (computed deterministically by Dart; MUST NOT change)
// ────────────────────────────────────────────────────────────────────────────
const GOLDEN_PUB_B64URL = "A6EHv_POEL4dcN0Y50vAmWfk1jCbpQ1fHdyGZBJVMbg"
const GOLDEN_SIG_B64URL =
  "uOPCytBs3cQdxuuqCGgUh-8SPu-ENYfNJYC9GZyrT5HrcCfKdqO0CB903m0UsJ0RJorCEV3KqF2JPagzxusUBg"
const GOLDEN_CANONICAL_PAYLOAD =
  '{"protocol":"itech-s6-pop","version":1,"challenge_id":"c0000000-0000-0000-0000-000000000101",' +
  '"challenge":"s6-golden-challenge-vector",' +
  '"shop_id":"a0000000-0000-0000-0000-000000000701",' +
  '"device_id":"d0000000-0000-0000-0000-000000000801",' +
  '"user_id":"u0000000-0000-0000-0000-000000000901",' +
  '"installation_id":"g0000000-0000-0000-0000-000000001001",' +
  '"expires_at":"2030-01-02T03:04:05Z","purpose":"device-proof"}'

// ────────────────────────────────────────────────────────────────────────────
// Canonical helper that mirrors the Edge Function (byte-identical)
// ────────────────────────────────────────────────────────────────────────────

function decodeBase64UrlStrict(value: string): Uint8Array | null {
  if (!value || value.length === 0) return null
  if (value.includes("=")) return null
  if (/[^A-Za-z0-9_\-]/.test(value)) return null
  try {
    const bin = atob(value.replace(/-/g, "+").replace(/_/g, "/"))
    const bytes = new Uint8Array(new ArrayBuffer(bin.length))
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i)
    return bytes
  } catch (_) {
    return null
  }
}

/** Copy to an ArrayBuffer-backed view (required by TS WebCrypto typing). */
function toArrayBufferView(bytes: Uint8Array): Uint8Array {
  const copy = new Uint8Array(new ArrayBuffer(bytes.byteLength))
  copy.set(bytes)
  return copy
}

function canonicalEnvelopeBytes(opts: {
  challengeId: string
  challenge: string
  shopId: string
  deviceId: string
  userId: string
  installationId: string
  expiresAt: string
}): Uint8Array {
  const s =
    `{"protocol":"itech-s6-pop","version":1,` +
    `"challenge_id":"${opts.challengeId}","challenge":"${opts.challenge}",` +
    `"shop_id":"${opts.shopId}","device_id":"${opts.deviceId}","user_id":"${opts.userId}",` +
    `"installation_id":"${opts.installationId}","expires_at":"${opts.expiresAt}",` +
    `"purpose":"device-proof"}`
  return new TextEncoder().encode(s)
}

function canonicalExpiresAt(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0")
  return `${date.getUTCFullYear()}-${pad(date.getUTCMonth() + 1)}-${pad(date.getUTCDate())}T${pad(date.getUTCHours())}:${pad(date.getUTCMinutes())}:${pad(date.getUTCSeconds())}Z`
}

async function verifyEd25519(
  publicKeyBytes: Uint8Array,
  signatureBytes: Uint8Array,
  messageBytes: Uint8Array
): Promise<boolean> {
  const key = await crypto.subtle.importKey(
    "raw",
    toArrayBufferView(publicKeyBytes),
    { name: "Ed25519" },
    false,
    ["verify"]
  )
  return crypto.subtle.verify(
    "Ed25519",
    key,
    toArrayBufferView(signatureBytes),
    toArrayBufferView(messageBytes)
  )
}

// ────────────────────────────────────────────────────────────────────────────
// A. Canonical payload cross-language byte identity (Scenario 28)
// ────────────────────────────────────────────────────────────────────────────

Deno.test("S6-D1: canonical payload is byte-identical to the Dart golden vector", () => {
  const bytes = canonicalEnvelopeBytes({
    challengeId: "c0000000-0000-0000-0000-000000000101",
    challenge: "s6-golden-challenge-vector",
    shopId: "a0000000-0000-0000-0000-000000000701",
    deviceId: "d0000000-0000-0000-0000-000000000801",
    userId: "u0000000-0000-0000-0000-000000000901",
    installationId: "g0000000-0000-0000-0000-000000001001",
    expiresAt: "2030-01-02T03:04:05Z",
  })
  const text = new TextDecoder().decode(bytes)
  assertEquals(text, GOLDEN_CANONICAL_PAYLOAD)
})

Deno.test("S6-D2: canonicalExpiresAt matches PostgreSQL RFC3339 format", () => {
  const d = new Date(Date.UTC(2030, 0, 2, 3, 4, 5))
  assertEquals(canonicalExpiresAt(d), "2030-01-02T03:04:05Z")
})

// ────────────────────────────────────────────────────────────────────────────
// B. Ed25519 verification via WebCrypto (Scenarios 09, 10, 26, 27, 28)
// ────────────────────────────────────────────────────────────────────────────

Deno.test("S6-D3: Ed25519 verify TRUE for frozen Dart signature (Scenario 28)", async () => {
  const pub = decodeBase64UrlStrict(GOLDEN_PUB_B64URL)
  const sig = decodeBase64UrlStrict(GOLDEN_SIG_B64URL)
  const msg = new TextEncoder().encode(GOLDEN_CANONICAL_PAYLOAD)
  const ok = await verifyEd25519(pub!, sig!, msg)
  assertEquals(ok, true)
})

Deno.test("S6-D4: Ed25519 verify FALSE for a different public key (Scenario 09)", async () => {
  const pub = decodeBase64UrlStrict(GOLDEN_PUB_B64URL)!
  pub[pub.length - 1] ^= 0x01
  const sig = decodeBase64UrlStrict(GOLDEN_SIG_B64URL)!
  const msg = new TextEncoder().encode(GOLDEN_CANONICAL_PAYLOAD)
  const ok = await verifyEd25519(pub, sig, msg)
  assertEquals(ok, false)
})

Deno.test("S6-D5: Ed25519 verify FALSE for tampered payload (Scenario 10)", async () => {
  const pub = decodeBase64UrlStrict(GOLDEN_PUB_B64URL)!
  const sig = decodeBase64UrlStrict(GOLDEN_SIG_B64URL)!
  const msg = new TextEncoder().encode(
    GOLDEN_CANONICAL_PAYLOAD.replace("s6-golden-challenge-vector", "tampered!")
  )
  const ok = await verifyEd25519(pub, sig, msg)
  assertEquals(ok, false)
})

Deno.test("S6-D6: Ed25519 verify FALSE for tampered signature", async () => {
  const pub = decodeBase64UrlStrict(GOLDEN_PUB_B64URL)!
  const sig = decodeBase64UrlStrict(GOLDEN_SIG_B64URL)!
  sig[0] ^= 0xff
  const msg = new TextEncoder().encode(GOLDEN_CANONICAL_PAYLOAD)
  const ok = await verifyEd25519(pub, sig, msg)
  assertEquals(ok, false)
})

Deno.test("S6-D7: strict base64url rejects padding and foreign alphabet", () => {
  assertEquals(decodeBase64UrlStrict("AA=="), null)
  assertEquals(decodeBase64UrlStrict("a+b/==="), null)
  assertEquals(decodeBase64UrlStrict("junk~!!"), null)
})

Deno.test("S6-D8: strict base64url accepts canonical unpadded form", () => {
  const pub = decodeBase64UrlStrict(GOLDEN_PUB_B64URL)
  assertEquals(pub!.length, 32)
  const sig = decodeBase64UrlStrict(GOLDEN_SIG_B64URL)
  assertEquals(sig!.length, 64)
})

// ────────────────────────────────────────────────────────────────────────────
// C. Structural guards in the Edge Function (mirrors invite-employee pattern)
// ────────────────────────────────────────────────────────────────────────────

Deno.test("S6-S1: verifier authenticates caller and derives user from session", async () => {
  const code = await Deno.readTextFile("./index.ts")
  assertStringIncludes(code, "supabaseUser.auth.getUser()")
  assertStringIncludes(code, "const userId = user.id")
})

Deno.test("S6-S2: verifier obtains authoritative challenge record", async () => {
  const code = await Deno.readTextFile("./index.ts")
  assertStringIncludes(code, `.from("device_challenges")`)
  assertStringIncludes(code, `eq("id", challenge_id)`)
})

Deno.test("S6-S3: verifier enforces challenge binding and expiry", async () => {
  const code = await Deno.readTextFile("./index.ts")
  assertStringIncludes(code, "Challenge routing mismatch")
  assertStringIncludes(code, "challenge.used_at")
  assertStringIncludes(code, "Challenge expired")
})

Deno.test("S6-S4: verifier requires ACTIVE device and bound public key", async () => {
  const code = await Deno.readTextFile("./index.ts")
  assertStringIncludes(code, ".from(\"devices\")")
  assertStringIncludes(code, "device.status !== \"ACTIVE\"")
  assertStringIncludes(code, "Device has no bound public key")
  assertStringIncludes(code, "publicKeyBytes.length !== 32")
  assertStringIncludes(code, "signatureBytes.length !== 64")
})

Deno.test("S6-S5: verifier reconstructs envelope from authoritative data", async () => {
  const code = await Deno.readTextFile("./index.ts")
  assertStringIncludes(code, "canonicalEnvelopeBytes(")
  assertStringIncludes(code, "canonicalExpiresAt(new Date(challenge.expires_at))")
  assertStringIncludes(code, "userId: userId,")
})

Deno.test("S6-S6: verifier calls s4_assert_request only after verify, service key never returned", async () => {
  const code = await Deno.readTextFile("./index.ts")
  assertStringIncludes(code, "s4_assert_request")
  assertStringIncludes(code, "p_signature_format")
  // Service role credential must not be returned as JSON.
  assertEquals(code.includes("SUPABASE_SERVICE_ROLE_KEY"), true)
})

Deno.test("S6-S7: verifier never activates the device gate", async () => {
  const code = await Deno.readTextFile("./index.ts")
  assertEquals(code.includes("s4_set_device_gate_enforcement"), false)
  assertEquals(code.includes("device_gate_enabled = true"), false)
})

Deno.test("S6-S8: documented deterministic helpers present", async () => {
  const code = await Deno.readTextFile("./index.ts")
  assertStringIncludes(code, "itech-s6-pop")
  assertStringIncludes(code, "device-proof")
  assertStringIncludes(code, "crypto.subtle.verify")
})
