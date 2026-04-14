-- ============================================================
-- Doubtless IAP: Database Schema
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Credit Balances Table
CREATE TABLE IF NOT EXISTS cred_balances (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    balance INT NOT NULL DEFAULT 0 CHECK (balance >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE cred_balances ENABLE ROW LEVEL SECURITY;

-- Clean up old potentially insecure policies from previous script version
DROP POLICY IF EXISTS "Users can insert own balance" ON cred_balances;
DROP POLICY IF EXISTS "Users can update own balance" ON cred_balances;
DROP POLICY IF EXISTS "Users can read own balance" ON cred_balances;

CREATE POLICY "Users can read own balance"
    ON cred_balances FOR SELECT
    USING (auth.uid() = user_id);

-- We REMOVED insert/update policies because ALL modifications 
-- should happen via secure RPC functions now, so the client cannot cheat.


-- 2. Credit Transactions Table
CREATE TABLE IF NOT EXISTS cred_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount INT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('purchase', 'session_deduct', 'welcome_bonus', 'solver_earning')),
    reference_id TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE cred_transactions ENABLE ROW LEVEL SECURITY;

-- Clean up old potentially insecure policies
DROP POLICY IF EXISTS "Users can insert own transactions" ON cred_transactions;
DROP POLICY IF EXISTS "Users can read own transactions" ON cred_transactions;

CREATE POLICY "Users can read own transactions"
    ON cred_transactions FOR SELECT
    USING (auth.uid() = user_id);
-- No insert policy. Handled via RPC only.


-- 3. Solver Earnings Table
CREATE TABLE IF NOT EXISTS solver_earnings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    solver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    doubt_id UUID NOT NULL,
    -- Using DECIMAL(10,2) to handle exactly 20.40 payouts
    amount DECIMAL(10,2) NOT NULL DEFAULT 20.40,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE solver_earnings ENABLE ROW LEVEL SECURITY;

-- Clean up old potentially insecure policies
DROP POLICY IF EXISTS "Authenticated users can insert earnings" ON solver_earnings;
DROP POLICY IF EXISTS "Solvers can read own earnings" ON solver_earnings;

CREATE POLICY "Solvers can read own earnings"
    ON solver_earnings FOR SELECT
    USING (auth.uid() = solver_id);
-- No insert policy. Handled via RPC only.


-- ============================================================
-- SECURE SERVER-SIDE RPC FUNCTIONS
-- ============================================================

-- A. Grant Welcome Bonus
CREATE OR REPLACE FUNCTION grant_welcome_bonus(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Only grant if they don't already have a balance row
    IF NOT EXISTS (SELECT 1 FROM cred_balances WHERE user_id = p_user_id) THEN
        INSERT INTO cred_balances (user_id, balance) VALUES (p_user_id, 60);
        INSERT INTO cred_transactions (user_id, amount, type, reference_id) 
               VALUES (p_user_id, 60, 'welcome_bonus', 'welcome');
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- B. Fulfill App Store Purchase
CREATE OR REPLACE FUNCTION fulfill_purchase(p_user_id UUID, p_amount INT, p_transaction_id TEXT)
RETURNS VOID AS $$
BEGIN
    -- Upsert balance
    INSERT INTO cred_balances (user_id, balance) 
    VALUES (p_user_id, p_amount)
    ON CONFLICT (user_id) 
    DO UPDATE SET balance = cred_balances.balance + p_amount, updated_at = NOW();

    -- Log transaction securely
    INSERT INTO cred_transactions (user_id, amount, type, reference_id) 
    VALUES (p_user_id, p_amount, 'purchase', p_transaction_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- C. Process Session Deduction (SERVER-SIDE ONLY)
-- This atomically checks balance, deducts 30 from student, 
-- and grants 20.40 to the solver all in one secure transaction.
CREATE OR REPLACE FUNCTION process_session_deduction(p_student_id UUID, p_solver_id UUID, p_doubt_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_current_balance INT;
BEGIN
    -- 1. Read and lock the student's balance row to prevent double spending
    SELECT balance INTO v_current_balance 
    FROM cred_balances 
    WHERE user_id = p_student_id 
    FOR UPDATE;

    -- 2. Check if they have at least 30 creds
    IF v_current_balance IS NULL OR v_current_balance < 30 THEN
        RETURN FALSE; -- Insufficient funds
    END IF;

    -- 3. Deduct 30 Creds from Student
    UPDATE cred_balances 
    SET balance = balance - 30, updated_at = NOW() 
    WHERE user_id = p_student_id;

    -- Log Student Deduction
    INSERT INTO cred_transactions (user_id, amount, type, reference_id) 
    VALUES (p_student_id, -30, 'session_deduct', p_doubt_id::text);

    -- 4. Credit Solver 20.40 (80% of the 25.50 remaining after Apple's 15% cut)
    INSERT INTO solver_earnings (solver_id, doubt_id, amount, status)
    VALUES (p_solver_id, p_doubt_id, 20.40, 'pending');

    -- Log Solver earning
    INSERT INTO cred_transactions (user_id, amount, type, reference_id) 
    VALUES (p_solver_id, 20.40, 'solver_earning', p_doubt_id::text);

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
