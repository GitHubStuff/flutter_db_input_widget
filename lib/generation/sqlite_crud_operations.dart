import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/io/db_project_io.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_tracers/trace.dart' as Log;

import '../flutter_db_input_widget.dart';
import 'column_declarations.dart';
import 'generator.dart';

class SQLiteCRUD {
  final Callback callback;
  final GeneratorIO generatorIO;
  final DBProjectBloc projectBloc;
  SQLiteCRUD({this.callback, this.generatorIO, this.projectBloc});

  /// Create(RUD)
  Future<dynamic> createSQLCreate() async {
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    List<String> keyList = List();
    List<String> valueList = List();
    keyList.add('${Headers.parentRowId},');
    valueList.add('\$_${Headers.parentRowId},');
    String previousKey = '${Headers.parentClassName}';
    String previousValue = '"\$_${Headers.parentClassName}"';
    for (DBRecord record in columnRecords) {
      final declaration = ColumnDeclarations(record: record);
      if (record.columnType == ColumnTypes.array || record.columnType == ColumnTypes.clazz) continue;
      keyList.add(previousKey + ',');
      valueList.add(previousValue + ',');
      switch (record.columnType) {
        case ColumnTypes.array:
          continue;
        case ColumnTypes.clazz:
          continue;
        case ColumnTypes.date:
        case ColumnTypes.string:
          previousKey = '${declaration.columnName}';
          previousValue = '"\$_${declaration.columnName}"';
          continue;
        case ColumnTypes.boolean:
        case ColumnTypes.double:
        case ColumnTypes.integer:
          previousKey = '${declaration.columnName}';
          previousValue = '\$_${declaration.columnName}';
          continue;
        default:
          Log.f('sqlite_declartion: unknown type ${record.columnType}');
      }
    }
    keyList.add(previousKey);
    valueList.add(previousValue);

    generatorIO.newSection(
        name: '///- SQLite Create Record', body: ['Future<int> createRecord() async {'], padding: Headers.classIndent);
    generatorIO.add(["final sql = '''INSERT INTO ${generatorIO.rootFileName}", "("], padding: Headers.levelIndent(1));
    generatorIO.add(keyList, padding: Headers.levelIndent(2));
    generatorIO.add([')', 'VALUES', '('], padding: Headers.levelIndent(1));
    generatorIO.add(valueList, padding: Headers.levelIndent(2));
    generatorIO.add([
      ")''';",
      '',
      'int newRowid = await SQL.SqliteController.database.rawInsert(sql);',
      'setRowid(newRowid);'
          'return rowid;',
    ], padding: Headers.levelIndent(1));
    generatorIO.add(['}'], padding: Headers.classIndent);
    callback('sqlite_declarations: completed sqlite insert');
    return null;
  }

  /// C(Read)UD
  Future<void> createSQLRead() {
    String sql = '''  ///- Return records of sql query
  Future<List<Map<String, dynamic>>> readRecord({String where, String orderBy = 'rowid'}) async {
    String sql = 'SELECT rowid,* from ${generatorIO.rootFileName}';
    if (where != null) sql += ' WHERE \$where';
    if (orderBy != null) sql += ' ORDER BY \$orderBy';
    var results = await SQL.SqliteController.database.rawQuery(sql).catchError((error, stack) {
       throw Exception(error.toString());
    });
    return results;
  }
''';
    generatorIO.newSection(name: '///- SQL READ', body: [sql]);
    return null;
  }

  /// CR(Update)D
  Future<dynamic> createSQLUpdate() async {
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    List<String> keyList = List();
    keyList.add('${Headers.parentRowId} = \$${Headers.parentRowId},');
    String previousKey = '${Headers.parentClassName} = "\$${Headers.parentClassName}"';
    for (DBRecord record in columnRecords) {
      final declaration = ColumnDeclarations(record: record);
      if (record.columnType == ColumnTypes.array || record.columnType == ColumnTypes.clazz) continue;
      keyList.add(previousKey + ',');
      switch (record.columnType) {
        case ColumnTypes.array:
        case ColumnTypes.clazz:
          continue;
        case ColumnTypes.date:
        case ColumnTypes.string:
          previousKey = '${declaration.columnName} = "\$${declaration.columnName}"';
          continue;
        case ColumnTypes.boolean:
        case ColumnTypes.double:
        case ColumnTypes.integer:
          previousKey = '${declaration.columnName} = \$${declaration.columnName}';
          continue;
        default:
          Log.f('sqlite_declartion: unknown type ${record.columnType}');
      }
    }
    keyList.add(previousKey);

    generatorIO.newSection(
        name: '///- SQLite Update Class (properties, arrays, classes)',
        body: [
          "Future<int> updateRecord({String where = 'rowid = rowid'}) async {",
        ],
        padding: Headers.classIndent);
    generatorIO.add(["final sql = '''UPDATE ${generatorIO.rootFileName}", "SET"], padding: Headers.levelIndent(1));
    generatorIO.add(keyList, padding: Headers.levelIndent(2));
    generatorIO.add(["WHERE \$where''';"], padding: Headers.levelIndent(1));
    generatorIO.add(['', 'return await SQL.SqliteController.database.rawUpdate(sql);'], padding: Headers.levelIndent(1));
    generatorIO.add(['}'], padding: Headers.classIndent);
    callback('sqlite_declarations: completed sqlite insert');
    return null;
  }

  /// CRU(Delete)
  Future<void> createSQLDelete() {
    generatorIO.newSection(
        name: '///- Create class delete method (properties, classes, arrays)',
        body: ['Future<void> deleteRecord() async {'],
        padding: Headers.classIndent);
    generatorIO.add(
        ["await SQL.SqliteController.database.rawDelete('DELETE FROM ${generatorIO.rootFileName} WHERE rowid = \$rowid');"],
        padding: Headers.classIndent + 3);
    generatorIO.add(['}'], padding: Headers.classIndent);
    return null;
  }
}
