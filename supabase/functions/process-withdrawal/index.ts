import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RAZORPAY_KEY_ID = "rzp_test_STxi6Cd3wWWmwE";
const RAZORPAY_KEY_SECRET = "up7jdmT6FzQzHk6YGZTA4l7I";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    const { withdrawal_id, solver_id, amount, upi_id } = await req.json();

    if (!withdrawal_id || !solver_id || !amount || !upi_id) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase with service role
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Update withdrawal status to 'processing'
    await supabase
      .from("withdrawal_requests")
      .update({ status: "processing", updated_at: new Date().toISOString() })
      .eq("id", withdrawal_id);

    // --- Step 1: Create a Razorpay Contact ---
    const contactRes = await fetch("https://api.razorpay.com/v1/contacts", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization:
          "Basic " + btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`),
      },
      body: JSON.stringify({
        name: `Solver ${solver_id.substring(0, 8)}`,
        type: "vendor",
        reference_id: solver_id,
      }),
    });

    if (!contactRes.ok) {
      const errText = await contactRes.text();
      throw new Error(`Razorpay Contact creation failed: ${errText}`);
    }

    const contact = await contactRes.json();

    // --- Step 2: Create a Fund Account (UPI) ---
    const fundAccountRes = await fetch(
      "https://api.razorpay.com/v1/fund_accounts",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization:
            "Basic " + btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`),
        },
        body: JSON.stringify({
          contact_id: contact.id,
          account_type: "vpa",
          vpa: {
            address: upi_id,
          },
        }),
      }
    );

    if (!fundAccountRes.ok) {
      const errText = await fundAccountRes.text();
      throw new Error(`Razorpay Fund Account creation failed: ${errText}`);
    }

    const fundAccount = await fundAccountRes.json();

    // --- Step 3: Create a Payout ---
    const amountInPaise = Math.round(parseFloat(amount) * 100);

    const payoutRes = await fetch("https://api.razorpay.com/v1/payouts", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization:
          "Basic " + btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`),
        "X-Payout-Idempotency": withdrawal_id, // Prevent duplicate payouts
      },
      body: JSON.stringify({
        account_number: "2323230085752163", // Your RazorpayX account number
        fund_account_id: fundAccount.id,
        amount: amountInPaise,
        currency: "INR",
        mode: "UPI",
        purpose: "payout",
        queue_if_low_balance: true,
        reference_id: withdrawal_id,
        narration: "Doubtless Solver Payout",
      }),
    });

    if (!payoutRes.ok) {
      const errText = await payoutRes.text();
      throw new Error(`Razorpay Payout creation failed: ${errText}`);
    }

    const payout = await payoutRes.json();

    // --- Step 4: Update withdrawal record with success ---
    await supabase
      .from("withdrawal_requests")
      .update({
        status: "completed",
        razorpay_payout_id: payout.id,
        updated_at: new Date().toISOString(),
      })
      .eq("id", withdrawal_id);

    return new Response(
      JSON.stringify({
        success: true,
        payout_id: payout.id,
        status: payout.status,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Withdrawal error:", error);

    // Try to mark withdrawal as failed
    try {
      const { withdrawal_id } = await req.clone().json();
      if (withdrawal_id) {
        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
        await supabase
          .from("withdrawal_requests")
          .update({
            status: "failed",
            failure_reason: error.message,
            updated_at: new Date().toISOString(),
          })
          .eq("id", withdrawal_id);
      }
    } catch (_) {
      // Ignore cleanup errors
    }

    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
