import 'package:flutter/cupertino.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/generation/column_declarations.dart';
import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/generation/generator.dart';
import 'package:flutter_db_input_widget/io/db_project_io.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';

class FactoryDeclarations {
  final Callback callback;
  final GeneratorIO generatorIO;
  final DBProjectBloc projectBloc;
  const FactoryDeclarations({@required this.callback, @required this.generatorIO, @required this.projectBloc});

  Future<void> makeFactories() async {
    await _fromJsonFactory();
  }

  Future<void> _fromJsonFactory() async {
    List<String> toJsonList = List();
    final tablename = generatorIO.rootFileName;
    generatorIO.newSection(
        name: '///- Factory fromJson',
        body: ['factory $tablename.fromJson(Map<String, dynamic> json) { '],
        padding: Headers.classIndent);
    generatorIO.add(['var _instance = ${generatorIO.rootFileName}('], padding: Headers.levelIndent(2));
    generatorIO.add([
      "${Headers.sqlRowid} : json[${Headers.sqlRowid}] ?? 0,",
      "${Headers.parentRowId} : json['${Headers.parentRowId}] ?? 0,",
    ], padding: Headers.levelIndent(3));
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: tablename);
    for (DBRecord record in columnRecords) {
      final column = ColumnDeclarations(record: record);
      generatorIO.add(["${column.columnName} : json['${column.columnName}'],"], padding: Headers.levelIndent(3));
      if (record.columnType == ColumnTypes.clazz) {
        toJsonList.add("'${column.columnName}': ${column.columnName}.toJson(),");
        continue;
      }
      if (record.columnType == ColumnTypes.array) {
        toJsonList.add("'${column.columnName}': jsonArray(${column.columnName}),");
        continue;
      }
      toJsonList.add("'${column.columnName}': ${column.columnName},");
    }
    generatorIO.add([');', 'return _instance;'], padding: Headers.levelIndent(2));
    generatorIO.add(['}'], padding: Headers.classIndent);
    generatorIO.newSection(name: '///- ToJson', body: ['Map<String, dynamic> toJson() => {'], padding: Headers.classIndent);
    generatorIO.add(["'${Headers.sqlRowid}': _${Headers.sqlRowid} ?? 0,"], padding: Headers.parameterIntent);
    generatorIO.add(["'${Headers.parentRowId}': _${Headers.parentRowId} ?? 0,"], padding: Headers.parameterIntent);
    generatorIO.add(toJsonList, padding: Headers.parameterIntent);
    generatorIO.add(['};'], padding: Headers.classIndent);
  }
}