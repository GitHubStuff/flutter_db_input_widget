import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/io/db_project_io.dart';

class SQLiteHelpers {
  static Future<void> createSQLCount({@required GeneratorIO generatorIO}) {
    final sql = '''
  ///- Return count of records in ${generatorIO.rootFileName}
  Future<int> count(String clause) async {
    final whereClause = (clause == null) ? '' : 'WHERE \$clause';
    final sql = 'SELECT COUNT("rowid") FROM ${generatorIO.rootFileName} \$whereClause';
    return Sqflite.firstIntValue(await SQL.SqliteController.database.rawQuery(sql));
  }''';
    generatorIO.newSection(name: '///- SQL Count of records', body: [sql], padding: Headers.classIndent);
    return null;
  }

  static Future<void> createSQLGetFirstRecord({@required GeneratorIO generatorIO}) {
    final sql = '''///- Return first record of sql query
  Future<Map<String, dynamic>> firstRecord({String where, String orderBy = 'rowid asc limit 1'}) async {
    if (orderBy == null) throw Exception('static first - orderBy string null');
    List<Map<String, dynamic>> results = await readRecord(where: where, orderBy: orderBy);
    return (results != null && results.length > 0) ? results[0] : null;
  }''';
    generatorIO.newSection(name: '///- SQL First record of query', body: [sql], padding: Headers.classIndent);
    return null;
  }
}
