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
    keyList.add('${Headers.parentRowid},');
    valueList.add('\${link.rowid},');
    String previousKey = '${Headers.parentTableName}';
    String previousValue = '"\${link.tableName}"';
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
        name: '///- SQLite Create ',
        body: ['Future<int> create({@required SQL.SQLiteLink link}) async {'],
        padding: Headers.classIndent);
    generatorIO.add([
      'await createTable();',
      'this.${Headers.parentRowid} = link.rowid;',
      "this.${Headers.parentTableName} = link.tableName;",
      "final sql = '''INSERT INTO ${generatorIO.tableName}",
      "(",
    ], padding: Headers.levelIndent(1));
    generatorIO.add(keyList, padding: Headers.levelIndent(3));
    generatorIO.add([')', 'VALUES', '('], padding: Headers.levelIndent(1));
    generatorIO.add(valueList, padding: Headers.levelIndent(3));
    generatorIO.add([
      ")''';",
      '',
      'int newRowid = await SQL.SqliteController.database.rawInsert(sql);',
      'this.rowid = newRowid;',
      'return this.rowid;',
    ], padding: Headers.levelIndent(1));
    generatorIO.add(['}'], padding: Headers.classIndent);
    callback('sqlite_declarations: completed sqlite insert');
    return null;
  }

  ///------------------------------------------------------------------------------------------------------------------------------
  ///- C(Read)UD
  Future<void> createSQLRead() {
    String sql =
        '''static Future<List<${generatorIO.rootFileName}>> read({SQL.SQLiteLink link, String whereClause, String orderBy = 'rowid'}) async {
    await createTable();
    final clause = whereClause ?? link?.clause;
    String sql = 'SELECT rowid,* from ${generatorIO.tableName}';
    if (clause != null) sql += ' WHERE \$clause';
    if (orderBy != null) sql += ' ORDER BY \$orderBy';
    List<Map<String,dynamic>> maps = await SQL.SqliteController.database.rawQuery(sql).catchError((error, stack) {
       throw Exception(error.toString());
    });
    List<${generatorIO.rootFileName}> results = List();
    for (Map<String,dynamic> map in maps) {
       final result = ${generatorIO.rootFileName}.fromJson(map);
       result.rowid = map['rowid'];
       results.add(result);
    }  
    return results;
  }''';
    generatorIO.newSection(name: '///- SQLite Read', body: [sql], padding: Headers.classIndent);
    return null;
  }

  ///------------------------------------------------------------------------------------------------------------------------------
  ///- CR(Update)D
  Future<dynamic> createSQLUpdate() async {
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    List<String> keyList = List();
    keyList.add('${Headers.parentRowid} = \$${Headers.parentRowid},');
    String previousKey = '${Headers.parentTableName} = "\$${Headers.parentTableName}"';
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
        name: '///- SQLite Update Class',
        body: ["Future<int> update({SQL.SQLiteLink link}) async {"],
        padding: Headers.classIndent);
    generatorIO.add([
      'final clause = link.clause;',
      'await createTable();',
      'this.${Headers.parentRowid} = link.rowid;',
      'this.${Headers.parentTableName} = link.tableName;',
      "final sql = '''UPDATE ${generatorIO.tableName}",
      "SET",
    ], padding: Headers.levelIndent(1));
    generatorIO.add(keyList, padding: Headers.levelIndent(2));
    generatorIO.add(["WHERE \$clause''';"], padding: Headers.levelIndent(1));
    generatorIO.add(['', 'return await SQL.SqliteController.database.rawUpdate(sql);'], padding: Headers.levelIndent(1));
    generatorIO.add(['}'], padding: Headers.classIndent);
    callback('sqlite_declarations: completed sqlite insert');
    return null;
  }

  ///------------------------------------------------------------------------------------------------------------------------------
  /// CRU(Delete)
  Future<void> createSQLDelete() {
    generatorIO.newSection(
        name: '///- Create Delete',
        body: ["Future<int> delete({SQL.SQLiteLink link, String where}) async {"],
        padding: Headers.classIndent);
    generatorIO.add([
      'await createTable();',
      'final clause = where ?? link?.clause;',
      "String sql = 'DELETE FROM ${generatorIO.tableName} ';",
      "if (where != null) sql = '\$sql WHERE \$clause';",
      "return await SQL.SqliteController.database.rawDelete(sql);",
    ], padding: Headers.classIndent + 3);
    generatorIO.add(['}'], padding: Headers.classIndent);
    return null;
  }
}
