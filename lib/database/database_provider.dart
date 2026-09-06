import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glaziovi/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  var disposed = false;
  ref.onDispose(() => disposed = true);

  final database = await AppDatabase.open();
  if (disposed) {
    await database.close();
  } else {
    ref.onDispose(() => unawaited(database.close()));
  }

  return database;
});
