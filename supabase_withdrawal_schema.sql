-- ============================================================
-- Doubtless: Withdrawal System Schema
-- Run this in Supabase SQL Editor
-- ============================================================

-- Withdrawal Requests Table
CREATE TABLE IF NOT EXISTS withdrawal_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    solver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    upi_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    razorpay_payout_id TEXT,
    failure_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Solvers can read own withdrawals" ON withdrawal_requests;
CREATE POLICY "Solvers can read own withdrawals"
    ON withdrawal_requests FOR SELECT
    USING (auth.uid() = solver_id);


-- Secure RPC: Process Withdrawal Request
-- Validates the solver has enough pending earnings, marks them as 'processing',
-- and creates a withdrawal_requests row. Returns the withdrawal request ID.
CREATE OR REPLACE FUNCTION request_withdrawal(p_solver_id UUID, p_upi_id TEXT)
RETURNS UUID AS $$
DECLARE
    v_pending_total DECIMAL(10,2);
    v_withdrawal_id UUID;
BEGIN
    -- 1. Lock the pending earning rows first for this solver (cannot use FOR UPDATE with SUM)
    PERFORM 1
    FROM solver_earnings
    WHERE solver_id = p_solver_id AND status = 'pending'
    FOR UPDATE;

    -- 2. Calculate total pending earnings safely on the locked rows
    SELECT COALESCE(SUM(amount), 0) INTO v_pending_total
    FROM solver_earnings
    WHERE solver_id = p_solver_id AND status = 'pending';

    -- 2. Must have at least ₹1 to withdraw
    IF v_pending_total < 1 THEN
        RAISE EXCEPTION 'Insufficient pending earnings (₹%)', v_pending_total;
    END IF;

    -- 3. Mark all pending earnings as 'paid'
    UPDATE solver_earnings
    SET status = 'paid'
    WHERE solver_id = p_solver_id AND status = 'pending';

    -- 4. Create a withdrawal request
    INSERT INTO withdrawal_requests (solver_id, amount, upi_id, status)
    VALUES (p_solver_id, v_pending_total, p_upi_id, 'pending')
    RETURNING id INTO v_withdrawal_id;

    RETURN v_withdrawal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
