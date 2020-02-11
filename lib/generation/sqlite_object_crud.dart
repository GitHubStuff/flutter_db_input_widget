import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/io/db_project_io.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';

import '../flutter_db_input_widget.dart';
import 'column_declarations.dart';
import 'generator.dart';

class SQLiteObjectCrud {
  final Callback callback;
  final GeneratorIO generatorIO;
  final DBProjectBloc projectBloc;
  SQLiteObjectCrud({this.callback, this.generatorIO, this.projectBloc});

  Future<void> createSQLCreateClass() async {
    generatorIO.newSection(
      name: '///- SQLite createInSql class (properties, arrays, classes)',
      body: ['Future<void> createInSql() async {'],
      padding: Headers.classIndent,
    );
    generatorIO.add(['int newRowId = await createRecord();', 'setRowid(newRowId);'], padding: Headers.levelIndent(1));
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    for (DBRecord record in columnRecords) {
      final declaration = ColumnDeclarations(record: record);
      if (record.columnType == ColumnTypes.array) {
        String code = '''
     for (${declaration.targetName} item in ${declaration.columnName}) {
        if (item == null) continue;
        item.setParentRowId(rowid);
        item.setParentClassName(className);
        await item.createInSql();
     }''';
        generatorIO.add([code]);
        continue;
      }
      if (record.columnType == ColumnTypes.clazz) {
        String code = '''
    if (${declaration.columnName} != null) {
      ${declaration.columnName}.setParentRowId(rowid);
      ${declaration.columnName}.setParentClassName(className);
      await ${declaration.columnName}.createInSql();
    }
    ''';
        generatorIO.blankLine;
        generatorIO.add([code]);
      }
    }
    generatorIO.add(['}\n'], padding: Headers.classIndent);
  }

  Future<void> createSQLReadClass() async {
    generatorIO.newSection(
        name: '///- SQLite readFromSql class',
        body: [
          'static Future<${generatorIO.rootFileName}> readFromSql({String parentTableName, int parentTableRowid}) async {',
        ],
        padding: Headers.classIndent);
    String sql = '''
    String whereClause;
    if (parentTableName != null) whereClause = "(parentClassName = '\$parentTableName'";
    if (parentTableRowid != null) {
      if (whereClause != null) {
        whereClause += ' AND ';
      } else {
        whereClause = '(';
      }
      whereClause += "parentRowId = \$parentTableRowid";
    }
    if (whereClause != null) whereClause += ')';
    List<Map<String,dynamic>> results = await readRecord(where: whereClause);
    if (results == null || results.length == 0) return null;
    rowid = (results[0])['rowid'];''';
    generatorIO.add([sql]);
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    bool firstItem = true;
    for (DBRecord record in columnRecords) {
      final declaration = ColumnDeclarations(record: record);
      if (record.columnType == ColumnTypes.array) {
        if (!firstItem) generatorIO.blankLine;
        firstItem = false;
        generatorIO.add(["result['${declaration.columnName}'] = await ${declaration.targetName}.readFromSql(where: \$clause);'"],
            padding: Headers.classIndent + 3);
        continue;
      }
      if (record.columnType == ColumnTypes.clazz) {
        if (!firstItem) generatorIO.blankLine;
        firstItem = false;
        generatorIO.add([
          "final first = await ${declaration.targetName}.readFromSql(where: \$clause);",
          "if (first != null && first.length > 1) throw Exception('Returned \${first.length} records (should be 1)');",
          "result['${declaration.columnName}'] = (first != null && first.length > 0) ? first[0];"
        ], padding: Headers.classIndent + 3);
        continue;
      }
    }
    generatorIO.blankLine;
    generatorIO.add(['final result = ${generatorIO.rootFileName}.fromJson(results);'], padding: Headers.classIndent + 1);
    generatorIO.add(['}']);
  }

  Future<void> createSQLUpdateClass() async {
    generatorIO.newSection(
        name: '///- SQLite updateWithSql class',
        body: [
          'Future<void> updateWithSql() async {',
        ],
        padding: Headers.classIndent);

    generatorIO.add([
      "final count = await updateRecord()','if (count != 1) throw Exception('Updated \$count records(s), should be 1');",
    ], padding: Headers.classIndent + 3);
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    for (DBRecord record in columnRecords) {
      final declaration = ColumnDeclarations(record: record);
      if (record.columnType == ColumnTypes.array || record.columnType == ColumnTypes.clazz) {
        generatorIO.blankLine;
        generatorIO.add(['await update${declaration.columnSetter}()}'], padding: Headers.classIndent + 3);
        continue;
      }
    }
    generatorIO.add(['return null'], padding: Headers.classIndent + 3);
    generatorIO.add(['}'], padding: Headers.classIndent);
  }

  Future<void> createSQLDeleteClass() async {
    generatorIO.newSection(
        name: '///- SQLite deleteWithSql class',
        body: [
          'Future<void> deleteWithSql() async {',
        ],
        padding: Headers.classIndent);

    generatorIO.add([
      "final count = await deleteRecord()','if (count != 1) throw Exception('Deleted \$count records(s), should be 1",
    ], padding: Headers.classIndent + 3);
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    for (DBRecord record in columnRecords) {
      final declaration = ColumnDeclarations(record: record);
      if (record.columnType == ColumnTypes.array || record.columnType == ColumnTypes.clazz) {
        generatorIO.blankLine;
        generatorIO.add(['await delete${declaration.columnSetter}()}'], padding: Headers.classIndent + 3);
        continue;
      }
    }
    generatorIO.add(['return null'], padding: Headers.classIndent + 3);
    generatorIO.add(['}'], padding: Headers.classIndent);
  }
}
