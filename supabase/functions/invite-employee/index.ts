import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

/**
 * Edge Function: invite-employee
 *
 * S4-hardened Owner-delivered secure token issuance (Governance Section L).
 *
 * Security model:
 *   - caller MUST be an authenticated ACTIVE owner of the target shop
 *   - NO never-sent temporary password is generated (CASE 20: no reusable
 *     password); the employee establishes their own credential at acceptance
 *   - ONE cryptographically random plaintext invitation token (>=128-bit
 *     entropy) is generated
 *   - ONLY the SHA-256 HEX hash of the token is persisted (invitations.token_hash,
 *     via s4_token_hash / extensions.digest semantics); the plaintext token is
 *     returned EXACTLY ONCE to the authorized Owner and is never stored
 *   - invitation issuance is server-authoritative and Owner-only (s4_create_invitation
 *     re-verifies s4_require_owner as defense in depth)
 *
 * Request body:
 *   - shop_id: UUID of the shop
 *   - email: email address of the employee to invite
 *   - display_name: display name for the employee
 *   - role: 'employee' | 'salesOnly'
 *
 * Response (success):
 *   - { success: true, invitation_id: UUID, token: "<plaintext one-time token>",
 *       user_id: UUID }
 *   The `token` value is the ONLY delivery of the plaintext; the Owner must
 *   forward it out-of-band to the intended employee.
 */

const sha256Hex = async (input: string): Promise<string> => {
  const data = new TextEncoder().encode(input)
  const digest = await crypto.subtle.digest("SHA-256", data)
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("")
}

const randomToken = (byteLength = 32): string => {
  const bytes = new Uint8Array(byteLength)
  crypto.getRandomValues(bytes)
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("")
}

serve(async (req) => {
  // Only allow POST
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ success: false, error: "Method not allowed" }),
      { status: 405, headers: { "Content-Type": "application/json" } }
    )
  }

  try {
    // Create Supabase client with service-role for admin operations
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // Create a client with the user's JWT to verify their identity
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

    // Verify the caller is authenticated
    const { data: { user }, error: authError } = await supabaseUser.auth.getUser()
    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid authentication" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      )
    }

    // Parse request body
    const { shop_id, email, display_name, role } = await req.json()

    if (!shop_id || !email || !role) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing required fields: shop_id, email, role" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    if (!["employee", "salesOnly"].includes(role)) {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid role. Must be 'employee' or 'salesOnly'" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // Verify the caller is an ACTIVE owner of the shop
    const { data: membership, error: memberError } = await supabaseAdmin
      .from("shop_members")
      .select("role, status")
      .eq("shop_id", shop_id)
      .eq("user_id", user.id)
      .single()

    if (memberError || !membership || membership.role !== "owner" || membership.status !== "ACTIVE") {
      return new Response(
        JSON.stringify({ success: false, error: "Only the shop owner can invite employees" }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      )
    }

    // Create/resolve the auth user. NO temporary password is ever set or sent
    // (CASE 20: no reusable password). The employee establishes/owns their own
    // credential at acceptance. `email_confirm: true` lets them self-serve via
    // the standard recovery/invite path without the issuer holding a password.
    const { data: authUser, error: createError } = await supabaseAdmin.auth.admin
      .createUser({
        email: email.trim().toLowerCase(),
        email_confirm: true,
      })

    let userId: string | null = null

    if (createError) {
      // If user already exists, try to get their ID
      if (createError.message?.includes("already") || createError.message?.includes("exists")) {
        const { data: existingUser } = await supabaseAdmin.auth.admin.getUserByEmail(email.trim().toLowerCase())
        if (!existingUser?.user?.id) {
          return new Response(
            JSON.stringify({ success: false, error: "Existing user lookup returned no valid user ID" }),
            { status: 500, headers: { "Content-Type": "application/json" } }
          )
        }
        userId = existingUser.user.id
      } else {
        return new Response(
          JSON.stringify({ success: false, error: `Failed to create user: ${createError.message}` }),
          { status: 500, headers: { "Content-Type": "application/json" } }
        )
      }
    } else {
      // User was created successfully, validate the response
      if (!authUser?.user?.id) {
        return new Response(
          JSON.stringify({ success: false, error: "User creation succeeded but returned no user ID" }),
          { status: 500, headers: { "Content-Type": "application/json" } }
        )
      }
      userId = authUser.user.id
    }

    // Explicit user_id guard before ANY membership/invitation write
    if (!userId) {
      return new Response(
        JSON.stringify({ success: false, error: "Failed to resolve user ID for membership" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    // General-purpose token covers 256 bits of entropy (>=128-bit required).
    const token = randomToken(32)
    // Persist ONLY the SHA-256 hex hash of the token (matches PostgreSQL
    // extensions.digest(token,'sha256') hex semantics used by accept_invitation).
    const tokenHash = await sha256Hex(token)

    // Server-authoritative, Owner-only issuance via the authenticated RPC so
    // auth.uid() resolves to the Owner (s4_require_owner enforces defense in depth).
    // Stores only token_hash; returns invitation_id.
    const expiryMs = 7 * 24 * 60 * 60 * 1000
    const { data: invitationId, error: inviteError } = await supabaseUser.rpc(
      "s4_create_invitation",
      {
        p_shop_id: shop_id,
        p_email: email.trim().toLowerCase(),
        p_role: role,
        p_token_hash: tokenHash,
        p_expires_at: new Date(Date.now() + expiryMs).toISOString(),
      }
    )

    if (inviteError) {
      return new Response(
        JSON.stringify({ success: false, error: `Failed to create invitation: ${inviteError.message}` }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    // Create shop membership (INVITED status) once the server accepted the
    // invitation record. Uses service-role (admin) so RLS does not block the
    // membership definition write.
    const { error: memberInsertError } = await supabaseAdmin
      .from("shop_members")
      .insert({
        shop_id,
        user_id: userId,
        role,
        status: "INVITED",
      })

    if (memberInsertError) {
      return new Response(
        JSON.stringify({ success: false, error: `Failed to create membership: ${memberInsertError.message}` }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    // TODO: Send invitation email (future SMTP integration). Until SMTP is live
    // the plaintext token is returned to the Owner for out-of-band delivery
    // (Governance Section L: SMTP is NOT mandatory).

    return new Response(
      JSON.stringify({
        success: true,
        invitation_id: invitationId,
        user_id: userId,
        token,
      }),
      { headers: { "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message || "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
