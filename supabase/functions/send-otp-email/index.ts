import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const BREVO_API_KEY = Deno.env.get("BREVO_API_KEY")!

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
    const { email } = await req.json()

    if (!email) {
      return new Response(JSON.stringify({ error: "Missing email" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      })
    }

    // Generate a random 4-digit OTP code server-side
    const otp_code = String(Math.floor(1000 + Math.random() * 9000))

    // Create admin client with service_role key to bypass RLS
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    // Store the OTP in the password_resets table (upsert on email)
    const { error: upsertError } = await supabaseAdmin
      .from("password_resets")
      .upsert(
        {
          email: email.toLowerCase().trim(),
          otp_code: otp_code,
          created_at: new Date().toISOString(),
          used: false,
        },
        { onConflict: "email" }
      )

    if (upsertError) {
      console.error("Upsert error:", upsertError)
      return new Response(JSON.stringify({ error: `Failed to store OTP: ${upsertError.message}` }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      })
    }

    // Send email via Brevo
    const res = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "api-key": BREVO_API_KEY,      // Brevo uses 'api-key' header
      },
      body: JSON.stringify({
        sender: { name: "Doubtless Team", email: "contactusdoubtless@gmail.com" },
        to: [{ email: email }],
        subject: "Your Password Reset Code - Doubtless",
        htmlContent: `
          <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 20px;">
            <h2 style="color: #333;">Password Reset</h2>
            <p>You requested a password reset for your Doubtless account.</p>
            <p>Your verification code is:</p>
            <div style="background: #f5f5f5; padding: 20px; text-align: center; border-radius: 12px; margin: 20px 0;">
              <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #333;">${otp_code}</span>
            </div>
            <p style="color: #666; font-size: 14px;">This code expires in 10 minutes.</p>
            <p style="color: #666; font-size: 14px;">If you didn't request this, please ignore this email.</p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
            <p style="color: #999; font-size: 12px;">— Team Doubtless</p>
          </div>
        `,
      }),
    })

    if (!res.ok) {
      const errorText = await res.text()
      console.error("Brevo API error:", errorText)
      return new Response(JSON.stringify({ error: `Brevo API failed: ${errorText}` }), {
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
