# Architecture & Data Models

## Tech Stack
- **Framework:** Flutter (cross-platform iOS & Android)
- **State Management:** Riverpod (flutter_riverpod)
- **Local Database:** sqflite (SQLite wrapper - relational, mature, well-supported)
- **Path Provider:** path_provider (for database file location)
- **UUID:** uuid (for generating unique IDs)

## Folder Structure
```
lib/
├── main.dart                    # App entry point
├── app.dart                     # MaterialApp configuration
├── core/
│   ├── database/
│   │   ├── database_helper.dart # SQLite setup, migrations
│   │   └── tables.dart          # Table creation SQL
│   └── theme/
│       └── app_theme.dart       # App theme & colors
├── features/
│   ├── groups/
│   │   ├── models/
│   │   │   └── group.dart       # Group model
│   │   ├── providers/
│   │   │   └── groups_provider.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   └── add_group_screen.dart
│   │   └── repositories/
│   │       └── group_repository.dart
│   ├── members/
│   │   ├── models/
│   │   │   └── member.dart      # Person/Member model
│   │   ├── providers/
│   │   │   └── members_provider.dart
│   │   └── repositories/
│   │       └── member_repository.dart
│   ├── expenses/
│   │   ├── models/
│   │   │   └── expense.dart     # Expense model
│   │   ├── providers/
│   │   │   └── expenses_provider.dart
│   │   ├── screens/
│   │   │   └── add_expense_screen.dart
│   │   └── repositories/
│   │       └── expense_repository.dart
│   └── balances/
│       ├── models/
│       │   └── balance.dart     # Balance/Settlement model
│       ├── providers/
│       │   └── balances_provider.dart
│       ├── screens/
│       │   └── group_detail_screen.dart
│       └── services/
│           └── debt_calculator.dart
```

## Data Models

### Group
| Field      | Type   | Description              |
|------------|--------|--------------------------|
| id         | TEXT   | UUID, primary key        |
| name       | TEXT   | Group name               |
| createdAt  | TEXT   | ISO 8601 timestamp       |

### Member
| Field    | Type   | Description              |
|----------|--------|--------------------------|
| id       | TEXT   | UUID, primary key        |
| name     | TEXT   | Member display name      |
| groupId  | TEXT   | FK -> Group.id           |

### Expense
| Field       | Type    | Description                    |
|-------------|---------|--------------------------------|
| id          | TEXT    | UUID, primary key              |
| description | TEXT    | What the expense was for       |
| amount      | REAL    | Total amount                   |
| paidById    | TEXT    | FK -> Member.id (who paid)     |
| groupId     | TEXT    | FK -> Group.id                 |
| createdAt   | TEXT    | ISO 8601 timestamp             |

### ExpenseSplit (join table)
| Field     | Type   | Description                     |
|-----------|--------|---------------------------------|
| id        | TEXT   | UUID, primary key               |
| expenseId | TEXT   | FK -> Expense.id                |
| memberId  | TEXT   | FK -> Member.id                 |
| amount    | REAL   | This member's share of expense  |

## Debt Calculation Algorithm (Equal Split MVP)

### Step 1: Calculate Net Balances
For each member in the group:
```
net_balance = total_paid - total_share_owed
```
- `total_paid` = SUM of all expenses where member is the payer
- `total_share_owed` = SUM of all their splits from ExpenseSplit

### Step 2: Generate Settlements (Greedy Algorithm)
```
function calculateSettlements(members):
    creditors = members where net_balance > 0, sorted DESC
    debtors = members where net_balance < 0, sorted ASC (most negative first)
    settlements = []

    while creditors not empty AND debtors not empty:
        creditor = creditors[0]
        debtor = debtors[0]

        transfer = min(creditor.balance, abs(debtor.balance))

        settlements.add(Settlement(
            from: debtor,
            to: creditor,
            amount: transfer
        ))

        creditor.balance -= transfer
        debtor.balance += transfer

        if creditor.balance == 0: remove from creditors
        if debtor.balance == 0: remove from debtors

    return settlements
```

### Balance Model (in-memory, not persisted)
| Field      | Type   | Description                 |
|------------|--------|-----------------------------|
| fromMember | Member | Who owes                    |
| toMember   | Member | Who is owed                 |
| amount     | double | Amount to transfer          |

## Database Schema (SQLite)
```sql
CREATE TABLE groups (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE members (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    group_id TEXT NOT NULL,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);

CREATE TABLE expenses (
    id TEXT PRIMARY KEY,
    description TEXT NOT NULL,
    amount REAL NOT NULL,
    paid_by_id TEXT NOT NULL,
    group_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    FOREIGN KEY (paid_by_id) REFERENCES members(id),
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);

CREATE TABLE expense_splits (
    id TEXT PRIMARY KEY,
    expense_id TEXT NOT NULL,
    member_id TEXT NOT NULL,
    amount REAL NOT NULL,
    FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(id)
);
```
