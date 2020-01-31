import 'package:flutter/material.dart';

const String fileHeader = ''''
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
''';

String database({@required String name, @required String tableNamesAsString}) {
  tableNamesAsString ??= '\n  NO TABLES???';
  return '''
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Database database;

$tableNamesAsString

const String _databaseName = "$name.db";
const int _databaseVersion = 1;

class DatabaseController {
  static String _lastTime;
  
  static Future<void> drop(String table) async {
    final sql = 'DROP TABLE IF EXISTS \$table';
    await database.execute(sql);
  }

/// 'database' is a global property available to all classes that
/// need to perform tasks. This initialize method performs the require
/// SQLite task: Get a Path, Open the database and perform a table creation
/// note: CREATE TABLE IF NOT EXISTS should be used to prevent error of duplicate table creation.
  static Future<void> initializeDatabase(String createTableString) async {
    final path = await _getDatabasePath(_databaseName);
    database = await openDatabase(path, version: _databaseVersion, onCreate: null, onUpgrade: _upgrade);
    if (createTableString != null) database.execute(createTableString);
  }

/// As SQLite is stored on the device, a database path to the name of a usable
/// directory is needed for both iOS/Android platforms.
  static Future<String> _getDatabasePath(String databaseName) async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, databaseName);
    if (!await Directory(dirname(path)).exists()) {
      await Directory(dirname(path)).create(recursive: true);
    }
    return path;
  }

/// Current if the database tables are changed, a new version for the
/// database signals that an upgrade action must occur. Currently that action
/// is to 'DROP TABLE' for each table. The table should be be rebuilt as ended
/// by the class that manages content of their tables.
  static Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('\${database.toString()}');
    if (database == null) return;
    throw Exception('Upgrade not implemented');
  }
}
 ''';
}
