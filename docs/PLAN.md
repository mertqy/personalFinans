# Implementation Plan: Universal TL (TRY) Display for Transactions

## Goal
Ensure all financial transactions (Income, Expense) are displayed in Turkish Lira (TL/TRY) across the entire application, regardless of their stored currency (USD, etc.). Transfers will remain in their original currencies if applicable (or per existing logic).

## Domains
- **Mobile (Flutter)**: UI components, screens, and modals.
- **Data Logic**: `AppUtils` for conversion and `providers` for data handling.
- **Reporting/Statistics**: Charts and summaries.

## Proposed Strategy
1. **Identify all UI points** where `Transaction.amount` is displayed.
2. **Standardize conversion logic**: Use `AppUtils.convertToBaseCurrency` (mapping currency to TRY) before passing to `AppUtils.formatCurrency`.
3. **Exceptions**: Skip conversion for `Transfer` types when they are explicitly displayed as movements between accounts of same currency, or ensure user understands the choice. (Per user: "transfer hariç").

---

## Phase 1: Exploration (explorer-agent)
- [ ] Map all screens displaying transactions: `HomeScreen`, `DashboardScreen`, `AccountDetailScreen`, `BudgetScreen`, `StatisticsScreen`.
- [ ] Map all modals: `TransactionModal`, `AddCardModal`, etc.
- [ ] Check `TransactionProvider` for any balance calculation logic that needs conversion.

## Phase 2: Implementation (mobile-developer)
- [ ] **Core Utilities**: Verify `AppUtils.convertToBaseCurrency` uses up-to-date or appropriate mock rates (since no live API was mentioned, probably fixed rates or existing utility).
- [ ] **Dashboard Screen**: Update total balance and transaction list item display.
- [ ] **Account Detail Screen**: Update transaction items.
- [ ] **Statistics Screen**: Ensure all custom charts (already updated) and lists use converted values.
- [ ] **Transaction Modals**: Update display of existing transaction details.

## Phase 3: Verification (test-engineer)
- [ ] Verify a USD account's transaction (e.g., $10) shows as its TRY equivalent (e.g., 320 TL) in the home list.
- [ ] Verify "Transfer" transactions still show their native amount if necessary.
- [ ] Check for edge cases: Subscriptions, Budget progress bars.

---

## ⏸️ CHECKPOINT: User Approval Needed
Please confirm if this plan covers all your requirements.
- Should 'Transfer' transactions show in original currency or converted to TL when seen in a 'Total Spending' context? (Plan currently follows "transfer hariç").
- Should the 'Exchange Rate' used be fixed or is there a service? (Currently assumes existing `AppUtils` logic).
