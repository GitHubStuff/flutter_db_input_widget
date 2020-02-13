import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/io/db_project_io.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';

import '../flutter_db_input_widget.dart';
import 'generator.dart';

class SqliteCRUDLinks {
  final Callback callback;
  final GeneratorIO generatorIO;
  final DBProjectBloc projectBloc;
  SqliteCRUDLinks({this.callback, this.generatorIO, this.projectBloc});

  Future<dynamic> sqlCreate() async {
    generatorIO.newSection(
        name: '///- SQLCreate Creates Linked Records',
        body: ['Future<SQL.SQLiteLink> createLink({SQL.SQLiteLink sqlLink}) async {'],
        padding: Headers.classIndent);
    generatorIO.add([
      "sqlLink ??= SQL.SQLiteLink(tableName: '${generatorIO.rootFileName}');",
      'this.rowid = await create(link: sqlLink);',
      'final childLink = SQL.SQLiteLink(rowid:this.rowid, tableName: className);',
    ], padding: Headers.classIndent + 3);
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    for (DBRecord record in columnRecords) {
      if (record.columnType != ColumnTypes.array && record.columnType != ColumnTypes.clazz) continue;
      if (record.columnType == ColumnTypes.array) {
        generatorIO.add(['${record.field}.forEach((rec) async => await rec.createLink(sqlLink: childLink));'],
            padding: Headers.classIndent + 3);
        generatorIO.blankLine;
      }
      if (record.columnType == ColumnTypes.clazz) {
        generatorIO.add(['await ${record.field}.createLink(sqlLink: childLink);'], padding: Headers.classIndent + 3);
        generatorIO.blankLine;
      }
    }
    generatorIO.add(['return childLink;  //- Returning link to root/base object (aka "key" for future use)'],
        padding: Headers.classIndent + 3);
    generatorIO.add(['}'], padding: Headers.classIndent);

    return null;
  }

  ///-------------------------------------------------------------------------------------------------------------------

  Future<dynamic> sqlRead() async {
    generatorIO.newSection(
        name: '///- SQLRead Read all linked records',
        body: ['static Future<List<${generatorIO.rootFileName}>> readLink({SQL.SQLiteLink sqlLink, String whereClause}) async {'],
        padding: Headers.classIndent);
    generatorIO.add([
      'if (sqlLink == null && whereClause == null) return null;',
      "final where = (sqlLink.tableName == '${generatorIO.rootFileName}') ? '(rowid = \${sqlLink.rowid})' : sqlLink.clause;",
      'List<${generatorIO.rootFileName}> list = await read(whereClause: where);',
    ], padding: Headers.classIndent + 3);
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    bool usingLink = false;
    for (DBRecord record in columnRecords) {
      if (record.columnType != ColumnTypes.array && record.columnType != ColumnTypes.clazz) continue;
      if (!usingLink)
        generatorIO.add([
          'for (${generatorIO.rootFileName} item in list) {',
          '   final SQL.SQLiteLink newLink = SQL.SQLiteLink(rowid: item.rowid, tableName: item.className);',
        ], padding: Headers.classIndent + 3);
      usingLink = true;
      if (record.columnType == ColumnTypes.array) {
        generatorIO.add([
          'item._${record.field} = await ${record.target}.readLink(sqlLink: newLink);',
        ], padding: Headers.classIndent + 6);
        generatorIO.blankLine;
      }
      if (record.columnType == ColumnTypes.clazz) {
        final target = record.target.toLowerCase();
        generatorIO.add([
          '/// Since read returns a List<>, only the first element is used (should be only one)',
          'List<${record.target}> _$target = await ${record.target}.readLink(sqlLink: newLink);',
          "if (_$target == null || _$target.length > 1) throw Exception('Missing data for ${record.target}');",
          'item._${record.field} = _$target[0];'
        ], padding: Headers.classIndent + 6);
        generatorIO.blankLine;
      }
    }
    if (usingLink) generatorIO.add(['}'], padding: Headers.classIndent + 3);
    generatorIO.add(['return list;'], padding: Headers.classIndent + 3);
    generatorIO.add(['}'], padding: Headers.classIndent);
    return null;
  }

  ///*** SPECIAL HELPER METHOD;
  Future<dynamic> sqlReadRoot() async {
    generatorIO.newSection(
        name: '///- SQLReadRoot Read all linked records based on root-key',
        body: ['static Future<${generatorIO.rootFileName}> readRoot({SQL.SQLiteLink sqlLink}) async {'],
        padding: Headers.classIndent);
    generatorIO.add([
      "assert(sqlLink != null);",
      "String clause = '(rowid = \${sqlLink.rowid})';",
      "List<${generatorIO.rootFileName}> list = await readLink(whereClause: clause);",
      "if (list == null || list.length != 1) throw SQLiteRecordNotFoundException('Cannot find record: \$clause', 400);",
      "return list[0];"
    ], padding: Headers.classIndent + 3);
    generatorIO.add(['}'], padding: Headers.classIndent);
  }

  ///-------------------------------------------------------------------------------------------------------------------
  Future<dynamic> sqlUpdate() async {
    generatorIO.newSection(
        name: '///- SQLUpdate update all linked records',
        body: ['Future<void> updateLink({SQL.SQLiteLink sqlLink}) async {'],
        padding: Headers.classIndent);
    generatorIO.add([
      'await update(link: sqlLink);',
    ], padding: Headers.classIndent + 3);

    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    bool usingLink = false;
    for (DBRecord record in columnRecords) {
      if (record.columnType != ColumnTypes.array && record.columnType != ColumnTypes.clazz) continue;
      if (!usingLink)
        generatorIO.add([
          'final childLink = SQL.SQLiteLink(rowid:this.rowid, tableName: this.className);',
        ], padding: Headers.classIndent + 6);
      usingLink = true;
      if (record.columnType == ColumnTypes.array) {
        generatorIO.add([
          '${record.field}.forEach((rec) async => await rec.updateLink(sqlLink: childLink));',
        ], padding: Headers.classIndent + 6);
        generatorIO.blankLine;
      }
      if (record.columnType == ColumnTypes.clazz) {
        generatorIO.add(['await ${record.field}.updateLink(sqlLink: childLink);'], padding: Headers.classIndent + 6);
        generatorIO.blankLine;
      }
    }
    generatorIO.add(['return null;'], padding: Headers.classIndent + 3);
    generatorIO.add(['}'], padding: Headers.classIndent);
    return null;
  }

  ///-------------------------------------------------------------------------------------------------------------------
  Future<dynamic> sqlDelete() async {
    generatorIO.newSection(
        name: '///- SQLDelete delete all linked records',
        body: ['Future<void> deleteLink({SQL.SQLiteLink sqlLink}) async {'],
        padding: Headers.classIndent);
    generatorIO.add([
      'await delete(link: sqlLink);',
    ], padding: Headers.classIndent + 3);

    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    bool usingChildLink = false;
    for (DBRecord record in columnRecords) {
      if (record.columnType != ColumnTypes.array && record.columnType != ColumnTypes.clazz) continue;
      if (!usingChildLink)
        generatorIO.add([
          'final childLink = SQL.SQLiteLink(rowid:this.rowid, tableName: className);',
        ], padding: Headers.classIndent + 3);
      usingChildLink = true;
      if (record.columnType == ColumnTypes.array) {
        generatorIO.blankLine;
        generatorIO.add([
          '${record.field}.forEach((rec) async => await rec.deleteLink(sqlLink: childLink));',
        ], padding: Headers.classIndent + 3);
      }
      if (record.columnType == ColumnTypes.clazz) {
        generatorIO.blankLine;
        generatorIO.add(['await ${record.field}.deleteLink(sqlLink: childLink);'], padding: Headers.classIndent + 3);
      }
    }
    generatorIO.add(['return null;'], padding: Headers.classIndent + 3);
    generatorIO.add(['}'], padding: Headers.classIndent);
    return null;
  }
}
