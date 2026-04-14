import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    })
  }

  try {
    const body = await req.json()
    const { user_id } = body

    if (!user_id) {
      return new Response(JSON.stringify({ error: "Missing user_id" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      })
    }

    // Create admin client with service_role key (auto-available in Edge Functions)
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    // 1. Delete user's cred balance
    await supabaseAdmin
      .from("cred_balances")
      .delete()
      .eq("user_id", user_id)

    // 2. Delete user's feedbacks (as student)
    await supabaseAdmin
      .from("feedbacks")
      .delete()
      .eq("student_id", user_id)

    // 3. Delete solver documents (if solver)
    await supabaseAdmin
      .from("solver_details")
      .delete()
      .eq("solver_id", user_id)

    // 4. Delete password reset records
    // Get user email first to clean up password_resets
    const { data: userData } = await supabaseAdmin.auth.admin.getUserById(user_id)
    if (userData?.user?.email) {
      await supabaseAdmin
        .from("password_resets")
        .delete()
        .eq("email", userData.user.email.toLowerCase())
    }

    // 5. Delete the auth user (this is the critical step)
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user_id)

    if (deleteError) {
      return new Response(JSON.stringify({ error: deleteError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      })
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    })
  } catch (error) {
    console.error("Error:", error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
})
