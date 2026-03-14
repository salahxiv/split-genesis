import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'split_genesis.db');

    return await openDatabase(
      path,
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        share_code TEXT,
        created_by_user_id TEXT,
        currency TEXT NOT NULL DEFAULT 'USD',
        type TEXT NOT NULL DEFAULT 'other',
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE members (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        group_id TEXT NOT NULL,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        amount_cents INTEGER NOT NULL DEFAULT 0,
        paid_by_id TEXT NOT NULL,
        group_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        expense_date TEXT,
        category TEXT NOT NULL DEFAULT 'general',
        split_type TEXT NOT NULL DEFAULT 'equal',
        currency TEXT NOT NULL DEFAULT 'USD',
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        FOREIGN KEY (paid_by_id) REFERENCES members(id) ON DELETE CASCADE,
        FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_splits (
        id TEXT PRIMARY KEY,
        expense_id TEXT NOT NULL,
        member_id TEXT NOT NULL,
        amount REAL NOT NULL,
        amount_cents INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
        FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_payers (
        id TEXT PRIMARY KEY,
        expense_id TEXT NOT NULL,
        member_id TEXT NOT NULL,
        amount REAL NOT NULL,
        amount_cents INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
        FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settlements (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        from_member_id TEXT NOT NULL,
        to_member_id TEXT NOT NULL,
        amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        from_member_name TEXT,
        to_member_name TEXT,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
        FOREIGN KEY (from_member_id) REFERENCES members(id) ON DELETE CASCADE,
        FOREIGN KEY (to_member_id) REFERENCES members(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_log (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        member_name TEXT,
        timestamp TEXT NOT NULL,
        metadata TEXT,
        sync_status TEXT DEFAULT 'pending',
        FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_comments (
        id TEXT PRIMARY KEY,
        expense_id TEXT NOT NULL,
        member_name TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE
      )
    ''');

    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_members_group_id ON members(group_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_group_id ON expenses(group_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_created_at ON expenses(created_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expense_splits_expense_id ON expense_splits(expense_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expense_payers_expense_id ON expense_payers(expense_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_settlements_group_id ON settlements(group_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_activity_log_group_id ON activity_log(group_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_groups_share_code ON groups(share_code)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_groups_sync_status ON groups(sync_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expense_comments_expense_id ON expense_comments(expense_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE expenses ADD COLUMN category TEXT NOT NULL DEFAULT 'general'");
      await db.execute(
          "ALTER TABLE expenses ADD COLUMN split_type TEXT NOT NULL DEFAULT 'equal'");
      await db.execute('''
        CREATE TABLE settlements (
          id TEXT PRIMARY KEY,
          group_id TEXT NOT NULL,
          from_member_id TEXT NOT NULL,
          to_member_id TEXT NOT NULL,
          amount REAL NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
          FOREIGN KEY (from_member_id) REFERENCES members(id) ON DELETE CASCADE,
          FOREIGN KEY (to_member_id) REFERENCES members(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE groups ADD COLUMN share_code TEXT');
    }
    if (oldVersion < 4) {
      await db.execute(
          'ALTER TABLE settlements ADD COLUMN from_member_name TEXT');
      await db.execute(
          'ALTER TABLE settlements ADD COLUMN to_member_name TEXT');
    }
    if (oldVersion < 5) {
      // Add sync columns to all tables
      await db.execute('ALTER TABLE groups ADD COLUMN created_by_user_id TEXT');
      await db.execute('ALTER TABLE groups ADD COLUMN updated_at TEXT');
      await db.execute(
          "ALTER TABLE groups ADD COLUMN sync_status TEXT DEFAULT 'pending'");

      await db.execute('ALTER TABLE members ADD COLUMN updated_at TEXT');
      await db.execute(
          "ALTER TABLE members ADD COLUMN sync_status TEXT DEFAULT 'pending'");

      await db.execute('ALTER TABLE expenses ADD COLUMN updated_at TEXT');
      await db.execute(
          "ALTER TABLE expenses ADD COLUMN sync_status TEXT DEFAULT 'pending'");

      await db.execute('ALTER TABLE settlements ADD COLUMN updated_at TEXT');
      await db.execute(
          "ALTER TABLE settlements ADD COLUMN sync_status TEXT DEFAULT 'pending'");

      // Create activity_log table
      await db.execute('''
        CREATE TABLE activity_log (
          id TEXT PRIMARY KEY,
          group_id TEXT NOT NULL,
          type TEXT NOT NULL,
          description TEXT NOT NULL,
          member_name TEXT,
          timestamp TEXT NOT NULL,
          metadata TEXT,
          sync_status TEXT DEFAULT 'pending',
          FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 6) {
      await _createIndexes(db);
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expense_payers (
          id TEXT PRIMARY KEY,
          expense_id TEXT NOT NULL,
          member_id TEXT NOT NULL,
          amount REAL NOT NULL,
          FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
          FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_expense_payers_expense_id ON expense_payers(expense_id)');
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE expenses ADD COLUMN expense_date TEXT');
      await db.execute("ALTER TABLE expenses ADD COLUMN currency TEXT NOT NULL DEFAULT 'USD'");
      await db.execute("ALTER TABLE groups ADD COLUMN currency TEXT NOT NULL DEFAULT 'USD'");
      await db.execute("ALTER TABLE groups ADD COLUMN type TEXT NOT NULL DEFAULT 'other'");
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expense_comments (
          id TEXT PRIMARY KEY,
          expense_id TEXT NOT NULL,
          member_name TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          sync_status TEXT DEFAULT 'pending',
          FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_expense_comments_expense_id ON expense_comments(expense_id)');
      // Backfill expense_date from created_at for existing rows
      await db.execute('UPDATE expenses SET expense_date = created_at WHERE expense_date IS NULL');
    }
    if (oldVersion < 9) {
      // Add integer cent columns; backfill from existing float columns.
      await db.execute('ALTER TABLE expenses ADD COLUMN amount_cents INTEGER NOT NULL DEFAULT 0');
      await db.execute('UPDATE expenses SET amount_cents = CAST(ROUND(amount * 100) AS INTEGER)');

      await db.execute('ALTER TABLE expense_splits ADD COLUMN amount_cents INTEGER NOT NULL DEFAULT 0');
      await db.execute('UPDATE expense_splits SET amount_cents = CAST(ROUND(amount * 100) AS INTEGER)');

      await db.execute('ALTER TABLE expense_payers ADD COLUMN amount_cents INTEGER NOT NULL DEFAULT 0');
      await db.execute('UPDATE expense_payers SET amount_cents = CAST(ROUND(amount * 100) AS INTEGER)');
    }
  }
}
