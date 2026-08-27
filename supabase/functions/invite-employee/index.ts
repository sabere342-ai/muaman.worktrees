import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

/**
 * Edge Function: invite-employee
 *
 * Creates an invited employee account and shop membership.
 *
 * Security:
 *   - Verifies caller is authenticated (JWT required)
 *   - Verifies caller is an ACTIVE owner of the target shop
 *   - Uses service-role for admin operations (user creation, membership insert)
 *
 * Request body:
 *   - shop_id: UUID of the shop
 *   - email: email address of the employee to invite
 *   - display_name: display name for the employee
 *   - role: 'employee' | 'salesOnly'
 *
 * Response:
 *   - { success: true, user_id: UUID } on success
 *   - { success: false, error: string } on failure
 */
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
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Create a client with the user's JWT to verify their identity
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: "Authentication required" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      )
    }

    const supabaseUser = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
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

    if (!['employee', 'salesOnly'].includes(role)) {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid role. Must be 'employee' or 'salesOnly'" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // Verify the caller is an ACTIVE owner of the shop
    const { data: membership, error: memberError } = await supabaseAdmin
      .from('shop_members')
      .select('role, status')
      .eq('shop_id', shop_id)
      .eq('user_id', user.id)
      .single()

    if (memberError || !membership || membership.role !== 'owner' || membership.status !== 'ACTIVE') {
      return new Response(
        JSON.stringify({ success: false, error: "Only the shop owner can invite employees" }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      )
    }

    // Create auth user with the admin client
    const { data: authUser, error: createError } = await supabaseAdmin.auth.admin
      .createUser({
        email: email.trim().toLowerCase(),
        email_confirm: true, // Auto-confirm for dev; enable confirmation in production
        password: crypto.randomUUID(), // Temporary password — employee will set their own
      })

    let userId: string | null = null

    if (createError) {
      // If user already exists, try to get their ID
      if (createError.message?.includes('already') || createError.message?.includes('exists')) {
        const { data: existingUser } = await supabaseAdmin.auth.admin.getUserByEmail(email.trim().toLowerCase())
        if (!existingUser?.user?.id) {
          return new Response(
            JSON.stringify({ success: false, error: 'Existing user lookup returned no valid user ID' }),
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
          JSON.stringify({ success: false, error: 'User creation succeeded but returned no user ID' }),
          { status: 500, headers: { "Content-Type": "application/json" } }
        )
      }
      userId = authUser.user.id
    }

    // Explicit user_id guard before ANY membership insert
    if (!userId) {
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to resolve user ID for membership' }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    // Create shop membership (INVITED status)
    const { error: memberInsertError } = await supabaseAdmin
      .from('shop_members')
      .insert({
        shop_id,
        user_id: userId,
        role,
        status: 'INVITED',
      })

    if (memberInsertError) {
      return new Response(
        JSON.stringify({ success: false, error: `Failed to create membership: ${memberInsertError.message}` }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    // Create invitation record
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
    const { error: inviteError } = await supabaseAdmin
      .from('invitations')
      .insert({
        shop_id,
        email: email.trim().toLowerCase(),
        role,
        invited_by: user.id,
        status: 'PENDING',
        expires_at: expiresAt,
      })

    if (inviteError) {
      // Invitation record is optional — membership was already created.
      console.error('Failed to create invitation record:', inviteError)
    }

    // TODO: Send invitation email (future SMTP integration)
    // await sendInvitationEmail(email, shop_name, invitation_token)

    return new Response(
      JSON.stringify({ success: true, user_id: userId }),
      { headers: { "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message || 'Internal server error' }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})