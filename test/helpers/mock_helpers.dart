import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:split_genesis/core/database/database_helper.dart';
import 'package:split_genesis/core/database/supabase_data_source.dart';
import 'package:split_genesis/core/services/connectivity_service.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockSupabaseDataSource extends Mock implements SupabaseDataSource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockDatabase extends Mock implements Database {
  MockTransaction? mockTransaction;

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action,
      {bool? exclusive}) async {
    return await action(mockTransaction ?? MockTransaction());
  }
}

class MockBatch extends Mock implements Batch {}

class MockTransaction extends Mock implements Transaction {}
