import 'package:flutter_db_input_widget/generation/column_declarations.dart';
import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/io/db_project_io.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_db_input_widget/src/db_project_bloc.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;
import 'package:flutter_tracers/trace.dart' as Log;

import 'generator.dart';

class SQLiteDeclarations {
  final Callback callback;
  final GeneratorIO generatorIO;
  final DBProjectBloc projectBloc;
  SQLiteDeclarations({this.callback, this.generatorIO, this.projectBloc});

  Future<dynamic> createSQLiteTable() async {
    List<String> additionalTables = List();
    generatorIO.newSection(name: 'SQLite Create Table', padding: Headers.classIndent);
    generatorIO.add(['static Future<dynamic> createTable() async {'], padding: Headers.classIndent);
    generatorIO
        .add(["final create = '''CREATE TABLE IF NOT EXISTS ${generatorIO.rootFileName} {"], padding: Headers.parameterIntent);
    String firstRow = '${Headers.parentRowId} INTEGER DEFAULT 0,';
    generatorIO.add([firstRow], padding: Headers.parameterIntent + 3);
    String previous = "${Headers.parentClassName} TEXT DEFAULT ''";
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    for (DBRecord record in columnRecords) {
      final sqliteType = record.sqliteType();
      if (sqliteType == null) {
        additionalTables.add('await ${Strings.capitalize(record.target)}.createTable();');
        continue;
      }
      generatorIO.add([previous + ','], padding: Headers.parameterIntent + 3);
      previous = '${Strings.lowercase(record.field)} $sqliteType';
    }
    generatorIO.add([previous, ")''';"], padding: Headers.parameterIntent + 3);
    generatorIO.blankLine;
    if (additionalTables.length > 0) {
      generatorIO.add(additionalTables, padding: Headers.parameterIntent);
      generatorIO.blankLine;
    }
    generatorIO.add(['await SQL.SqliteController.database.execute(create);'], padding: Headers.parameterIntent);
    generatorIO.add(['}'], padding: Headers.classIndent);
    return null;
  }

  Future<dynamic> createSQLInsert() async {
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

    generatorIO.newSection(name: '/// SQLite Insert Record', body: ['Future<int> insert() async {'], padding: Headers.classIndent);
    generatorIO.add(["final sql = '''INSERT INTO ${generatorIO.rootFileName}", "("], padding: Headers.levelIndent(1));
    generatorIO.add(keyList, padding: Headers.levelIndent(2));
    generatorIO.add([')', 'VALUES', '('], padding: Headers.levelIndent(1));
    generatorIO.add(valueList, padding: Headers.levelIndent(2));
    generatorIO.add([")''';", '', 'return await SQL.SqliteController.database.rawInsert(sql);'], padding: Headers.levelIndent(1));
    generatorIO.add(['}'], padding: Headers.classIndent);
    callback('sqlite_declarations: completed sqlite insert');
    return null;
  }

  Future<void> createSQLRestore() async {
    generatorIO.newSection(
      name: '///- SQLite restore json record',
      body: ['static Future<List<Map<String, dynamic>>> restoreJsonFromSQL({String where}) async {'],
      padding: Headers.classIndent,
    );
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    generatorIO.add([
      "List<Map<String, dynamic>> result = await ${generatorIO.rootFileName}.selectSQL(where: where);",
    ], padding: Headers.levelIndent(1));

    List<String> header = [
      "int parentId;",
      "String parentName;",
      "for (Map<String, dynamic> item in result) {",
      "   parentId = item['${Headers.parentRowId}'];",
      "   if (parentId == null || parentId == 0) throw Exception('Invalid state - parentId \$parentId');",
      "   parentName = item['${Headers.parentClassName}'];",
      "   if (parentName == null || parentName == '') throw Exception('Invalid state - parentName \"\$parentName\"');",
      "   String whereClause = \"(${Headers.parentRowId} = parentId AND ${Headers.parentClassName} = '\$parentName\')\";",
    ];
    bool first = true;
    for (DBRecord record in columnRecords) {
      final declaration = ColumnDeclarations(record: record);
      if (record.columnType == ColumnTypes.array) {
        if (first) generatorIO.add(header, padding: Headers.classIndent + 3);
        first = false;
        String code = '''
         item['${declaration.columnName}'] = await ${declaration.targetName}.restoreJsonFromSQL(where: whereClause);
        ''';
        generatorIO.add([code]);
        continue;
      }
      if (record.columnType == ColumnTypes.clazz) {
        if (first) generatorIO.add(header, padding: Headers.classIndent + 3);
        first = false;
        String code = '''
        List<Map<String, dynamic>> tempList = await ${declaration.targetName}.restoreJsonFromSQL(where: whereClause);
        if (tempList.length > 1) debugPrint('⁉️: class property ${declaration.columnName} as \${tempList.length} records!');
        item['${declaration.columnName}'] = tempList.first;
        ''';
        generatorIO.add([code]);
        continue;
      }
    }
    if (!first) generatorIO.add(['  }']);
    generatorIO.add(['    return result;', '}'], padding: Headers.classIndent);
  }

  Future<void> createSQLSave() async {
    generatorIO.newSection(
      name: '///- SQLite save record',
      body: ['Future<void> saveToSql() async {'],
      padding: Headers.classIndent,
    );
    generatorIO.add(['rowid = await insert();'], padding: Headers.levelIndent(1));
    generatorIO.blankLine;
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    for (DBRecord record in columnRecords) {
      final declaration = ColumnDeclarations(record: record);
      if (record.columnType == ColumnTypes.array) {
        String code = '''
    for (${declaration.targetName} item in ${declaration.columnName}) {
       item.setParentRowId(rowid);
       item.setParentClassName(${Headers.parentClassName});
       await item.saveToSql();
    }''';
        generatorIO.add([code]);
        continue;
      }
      if (record.columnType == ColumnTypes.clazz) {
        String code = '''
    ${declaration.columnName}.setParentRowId(rowid);
    ${declaration.columnName}.setParentClassName(parentClassName);
    await ${declaration.columnName}.saveToSql();
    ''';
        generatorIO.blankLine;
        generatorIO.add([code]);
      }
    }
    generatorIO.add(['}\n'], padding: Headers.classIndent);
  }
}
