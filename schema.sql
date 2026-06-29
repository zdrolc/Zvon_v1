-- Enable UUID extension for generating unique IDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 1. BANKING CONNECTIONS (Enable Banking)
-- ==============================================================================

-- Replaces gocardless_requisitions
CREATE TABLE enable_banking_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id TEXT NOT NULL, -- The session ID returned by POST /sessions
    aspsp_id TEXT NOT NULL, -- The bank identifier (e.g., 'SWEDBANK_EE', 'REVOLUT_EU')
    status TEXT NOT NULL DEFAULT 'AUTHORIZED', 
    access_valid_until TIMESTAMPTZ, -- Token expiration time
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 2. CORE FINANCIAL TABLES
-- ==============================================================================

CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES enable_banking_sessions(id) ON DELETE SET NULL,
    external_account_id TEXT UNIQUE, -- Enable Banking's account_uid
    bank_name TEXT,
    account_name TEXT,
    currency TEXT DEFAULT 'EUR',
    balance NUMERIC(15, 2) DEFAULT 0.00,
    iban TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category_group TEXT,
    color TEXT,
    expense_type TEXT, -- e.g., 'FIXED', 'VARIABLE', 'DISCRETIONARY'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE categorization_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    search_term TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 3. TRANSACTIONS
-- ==============================================================================

-- Raw data precisely as it arrives from Enable Banking
CREATE TABLE transactions_raw (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
    external_transaction_id TEXT UNIQUE NOT NULL, -- Enable Banking transaction_id
    booking_date DATE NOT NULL,
    value_date DATE,
    amount NUMERIC(15, 2) NOT NULL,
    currency TEXT DEFAULT 'EUR',
    creditor_name TEXT,
    creditor_account TEXT,
    debtor_name TEXT,
    debtor_account TEXT,
    remittance_information TEXT, -- Usually contains the payment reference/description
    status TEXT,
    raw_data JSONB, -- Dump the full Enable Banking JSON here for debugging/ETL fallback
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User-facing transactions (mutable layer)
CREATE TABLE transactions_user (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    raw_transaction_id UUID REFERENCES transactions_raw(id) ON DELETE CASCADE UNIQUE,
    account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    auto_category BOOLEAN DEFAULT FALSE,
    custom_date DATE,
    notes TEXT,
    is_ignored BOOLEAN DEFAULT FALSE,
    is_reviewed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE transaction_splits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_user_id UUID REFERENCES transactions_user(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    amount NUMERIC(15, 2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 4. BUDGETING & ADVANCED FEATURES
-- ==============================================================================

CREATE TABLE monthly_budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    month DATE NOT NULL, -- Stored as the first day of the month (e.g., 2026-06-01)
    total_budget NUMERIC(15, 2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, month)
);

CREATE TABLE category_budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    budget_id UUID REFERENCES monthly_budgets(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    amount NUMERIC(15, 2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(budget_id, category_id)
);

CREATE TABLE shared_expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_user_id UUID REFERENCES transactions_user(id) ON DELETE CASCADE,
    shared_with TEXT NOT NULL,
    amount_owed NUMERIC(15, 2) NOT NULL,
    is_settled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE provisions_and_amortizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    total_amount NUMERIC(15, 2) NOT NULL,
    monthly_amount NUMERIC(15, 2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 5. VIEWS
-- ==============================================================================

CREATE OR REPLACE VIEW transactions_view AS
SELECT 
    tu.id AS user_transaction_id,
    tr.id AS raw_transaction_id,
    tu.user_id,
    a.id AS account_id,
    a.account_name,
    COALESCE(tu.custom_date, tr.booking_date) AS transaction_date,
    tr.amount,
    tr.currency,
    tr.creditor_name,
    tr.debtor_name,
    tr.remittance_information,
    c.id AS category_id,
    c.name AS category_name,
    c.category_group,
    c.color AS category_color,
    c.expense_type,
    tu.notes,
    tu.is_ignored,
    tu.is_reviewed,
    tu.auto_category
FROM transactions_user tu
JOIN transactions_raw tr ON tu.raw_transaction_id = tr.id
JOIN accounts a ON tu.account_id = a.id
LEFT JOIN categories c ON tu.category_id = c.id;

-- ==============================================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- Enable RLS on all tables
ALTER TABLE enable_banking_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorization_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions_raw ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE category_budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE provisions_and_amortizations ENABLE ROW LEVEL SECURITY;

-- 1. Banking Connections
CREATE POLICY "Users can manage their own sessions" ON enable_banking_sessions 
FOR ALL USING (auth.uid() = user_id);

-- 2. Core Tables
CREATE POLICY "Users can manage their own accounts" ON accounts 
FOR ALL USING (auth.uid() = user_id);

-- Categories & Rules (Allow reading global null user_id, but only modifying own)
CREATE POLICY "Users can view global and own categories" ON categories 
FOR SELECT USING (user_id IS NULL OR user_id = auth.uid());

CREATE POLICY "Users can insert own categories" ON categories 
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own categories" ON categories 
FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete own categories" ON categories 
FOR DELETE USING (user_id = auth.uid());

CREATE POLICY "Users can view global and own rules" ON categorization_rules 
FOR SELECT USING (user_id IS NULL OR user_id = auth.uid());

CREATE POLICY "Users can modify own rules" ON categorization_rules 
FOR ALL USING (auth.uid() = user_id);

-- 3. Transactions
-- Raw transactions rely on account ownership
CREATE POLICY "Users can manage raw transactions for their accounts" ON transactions_raw 
FOR ALL USING (account_id IN (SELECT id FROM accounts WHERE user_id = auth.uid()));

CREATE POLICY "Users can manage their own user transactions" ON transactions_user 
FOR ALL USING (auth.uid() = user_id);

-- Splits rely on transaction_user ownership
CREATE POLICY "Users can manage splits for their transactions" ON transaction_splits 
FOR ALL USING (transaction_user_id IN (SELECT id FROM transactions_user WHERE user_id = auth.uid()));

-- 4. Budgeting & Advanced
CREATE POLICY "Users can manage their own monthly budgets" ON monthly_budgets 
FOR ALL USING (auth.uid() = user_id);

-- Category budgets rely on monthly budget ownership
CREATE POLICY "Users can manage their own category budgets" ON category_budgets 
FOR ALL USING (budget_id IN (SELECT id FROM monthly_budgets WHERE user_id = auth.uid()));

-- Shared expenses rely on transaction ownership
CREATE POLICY "Users can manage shared expenses for their transactions" ON shared_expenses 
FOR ALL USING (transaction_user_id IN (SELECT id FROM transactions_user WHERE user_id = auth.uid()));

CREATE POLICY "Users can manage their own provisions" ON provisions_and_amortizations 
FOR ALL USING (auth.uid() = user_id);
