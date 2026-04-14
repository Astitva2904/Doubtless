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
    const { email, otp_code, new_password, action } = body

    // Create admin client with service_role key (auto-available in Edge Functions)
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    // ---------- ACTION: verify-otp ----------
    // Just verifies if the OTP is valid without resetting the password
    if (action === "verify-otp") {
      if (!email || !otp_code) {
        return new Response(JSON.stringify({ error: "Missing email or otp_code" }), {
          status: 400,
          headers: { "Content-Type": "application/json" },
        })
      }

      const { data: records, error: fetchError } = await supabaseAdmin
        .from("password_resets")
        .select("*")
        .eq("email", email.toLowerCase().trim())
        .eq("otp_code", otp_code)
        .eq("used", false)

      if (fetchError) {
        return new Response(JSON.stringify({ error: fetchError.message }), {
          status: 500,
          headers: { "Content-Type": "application/json" },
        })
      }

      if (!records || records.length === 0) {
        return new Response(JSON.stringify({ valid: false }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        })
      }

      // Check expiry (10 minutes)
      const record = records[0]
      const createdAt = new Date(record.created_at)
      const elapsed = (Date.now() - createdAt.getTime()) / 1000
      if (elapsed > 600) {
        return new Response(JSON.stringify({ valid: false }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        })
      }

      return new Response(JSON.stringify({ valid: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      })
    }

    // ---------- ACTION: reset-password (default) ----------
    if (!email || !new_password) {
      return new Response(JSON.stringify({ error: "Missing email or new_password" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      })
    }

    // Find the user by email
    const { data: users, error: listError } = await supabaseAdmin.auth.admin.listUsers()

    if (listError) {
      return new Response(JSON.stringify({ error: listError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      })
    }

    const user = users.users.find(
      (u: any) => u.email?.toLowerCase() === email.toLowerCase()
    )

    if (!user) {
      return new Response(JSON.stringify({ error: "User not found" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      })
    }

    // Update the user's password
    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
      user.id,
      { password: new_password }
    )

    if (updateError) {
      return new Response(JSON.stringify({ error: updateError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      })
    }

    // Mark OTP as used (using service role to bypass RLS)
    await supabaseAdmin
      .from("password_resets")
      .update({ used: true })
      .eq("email", email.toLowerCase().trim())

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
