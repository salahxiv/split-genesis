# Market Analysis: Expense Splitting Apps

## Apps Analyzed
- **Splitwise** - Feature leader, requires accounts
- **Tricount** - Simplicity leader, no account required
- **Splid** - Offline-first, flexibility leader

## Core User Flows

### 1. Creating a Group
- All apps: tap "+" or "Create group" from home screen
- Group name required; optional category/image
- **Key differentiator:** Tricount/Splid require NO accounts (add by name only), Splitwise requires email/phone

### 2. Adding Members
- Splitwise: invite by email/phone (high friction)
- Tricount: add by name, share group via link
- Splid: add by name, share via unique code

### 3. Adding an Expense (Core Flow)
```
Description -> Amount -> Who Paid -> Split Method -> Confirm
```
- Default: equal split among all members (~80% of use cases)
- Split methods: Equal, Exact amounts, Percentages, Shares
- Progressive disclosure: unequal splits hidden behind a tap
- Real-time validation bar for custom amounts

### 4. Settling Debts
- Calculate net balance per member (total paid - total share)
- Debt simplification algorithm minimizes transactions
- Display: "A pays B: $X" format
- Green = money owed TO you, Red = money YOU owe

## UI Best Practices
1. **Bottom navigation** with Groups as primary tab
2. **Floating Action Button (FAB)** for adding expenses (most frequent action)
3. **Green/Red color coding** for positive/negative balances
4. **Large summary balance** at top of group/dashboard screens
5. **Per-member breakdowns** below summary
6. **3-4 taps** for common case (equal split)
7. **Smart defaults**: equal split, all members included

## Debt Calculation Algorithm
1. Calculate each member's net balance (total_paid - total_share)
2. Positive balance = creditor, Negative = debtor
3. Match largest creditor with largest debtor
4. Transfer minimum of what is owed/due
5. Repeat until all balances are zero

## Design Recommendations for Our App
1. Default to equal split
2. No account required for members
3. Offline-first with local database
4. Green/red color coding for balances
5. Show net balance prominently
6. FAB for "Add Expense"
7. Keep add-expense flow to 3-4 taps
8. Implement debt simplification
