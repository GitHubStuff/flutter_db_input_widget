import 'package:intl/intl.dart' as INTL;

const String _fileHeader = '''
/// AUTO-GENERATED CODE - DO NOT MODIFY IF POSSIBLE
/// Created: [DATE]

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_sqlite_controller/flutter_sqlite_controller.dart' as SQL;
import 'package:flutter_tracers/trace.dart' as Log;
''';

String libraryHeader() {
  final heading = '''
/// AUTO-GENERATED CODE - DO NOT MODIFY IF POSSIBLE
/// Created: [DATE]
''';
  final timestamp = INTL.DateFormat('MMMM dd,yyyy HH:mm').format(DateTime.now().toUtc()) + '(utc)';
  final result = heading.replaceFirst('[DATE]', timestamp);
  return result;
}

String tableHeader() {
  final timestamp = INTL.DateFormat('MMMM dd,yyyy HH:mm').format(DateTime.now().toUtc()) + '(utc)';
  final result = _fileHeader.replaceFirst('[DATE]', timestamp);
  return result;
}

String createStaticBuilders(String classname) {
  final code = '''
  static $classname build(dynamic data) {
    if (data is null) return null;
    if (data is Map) return $classname.fromJson(data);
    if (data is $classname) return data;
    throw Exception('static ${classname}Build could not parse: \${data.toString()}');
  }
  
  static List<$classname> buildArray(List<dynamic> array) {
    List<$classname> result = List();
    for (dynamic item in array) {
       if (item is null) result.add(null);
       if (item is $classname) result.add(item);
       if (item is Map) result.add($classname.fromJson(item));
    }
    return result;
  }
''';
  return code;
}

String createSQLSelectStatement(String tableName) {
  String sql = '''
  ///- Return count of records in $tableName
  static Future<int> count(String clause) async {
    final whereClause = (clause == null) ? '' : 'WHERE \$clause';
    final sql = 'SELECT COUNT("rowid") FROM $tableName \$whereClause';
    return Sqflite.firstIntValue(await SQL.SqliteController.database.rawQuery(sql));
  }
  
  ///- Return first record of sql query
  static Future<Map<String, dynamic>> firstSQL({String where, String orderBy = 'rowid asc limit 1'}) async {
     if (orderBy == null) throw Exception('static first - orderBy string null');
     List<Map<String, dynamic>> results = await selectSQL(where: where, orderBy: orderBy);
     return results.length > 0 ? results[0] : null;
  }
  
  ///- Return all records of sql query
  static Future<List<Map<String, dynamic>>> selectSQL({String where, String orderBy = 'rowid'}) async {
    String sql = 'SELECT rowid,* from $tableName';
    if (where != null) sql += ' WHERE \$where';
    if (orderBy != null) sql += ' ORDER BY \$orderBy';
    var results = await SQL.SqliteController.database.rawQuery(sql).catchError((error, stack) {
       throw Exception(error.toString());
    });
    return results;
  }
''';
  return sql;
}

/// Constants used in composing file names, as these are shared across creating various files
/// they are fixed any changes to how names are done requires just changing these.
const columnPrefix = 'column';
const libraryPrefix = 'sqlite_';
const librarySuffix = '_library';
const tablePrefix = 'table_';

const int classIndent = 3;
const int parameterIntent = 7;
const int trailingComment = 5;

const String parentRowId = 'parentRowId';
const String parentClassName = 'parentClassName';
const String sqlRowid = 'rowid';
const String suffix = '.g.txt';

int levelIndent(int level) => (classIndent + 2 * level);
