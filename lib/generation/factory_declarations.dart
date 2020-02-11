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

  /// Create a Map<String,dynamic> property that can be used to PUT to server/cloud endpoint, this uses
  /// the 'json' field that was added in the form.
  Future<void> createInlineCloudMapProperty() {
    generatorIO.newSection(name: '///- ToCloud', body: ['Map<String, dynamic> toCloud() => {'], padding: Headers.classIndent);
    List<String> toJsonList = List();
    final tablename = generatorIO.rootFileName;
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: tablename);
    for (DBRecord record in columnRecords) {
      final column = ColumnDeclarations(record: record);
      if (record.columnType == ColumnTypes.clazz) {
        toJsonList.add("'${record.json}': ${column.columnName}.toJson(),");
        continue;
      }
      if (record.columnType == ColumnTypes.array) {
        toJsonList.add("'${record.json}': jsonArray<${column.targetName}>(${column.columnName}),");
        continue;
      }
      toJsonList.add("'${record.json}': ${column.columnName},");
    }
    generatorIO.add(toJsonList, padding: Headers.parameterIntent);
    generatorIO.add(['};'], padding: Headers.classIndent);
    return null;
  }

  /// Properties, List<object>, and 'class'-properties to json format (Map<String, dynamic>)
  Future<void> createInlineMapProperty() {
    generatorIO.newSection(name: '///- ToJson', body: ['Map<String, dynamic> toJson() => {'], padding: Headers.classIndent);
    generatorIO.add(["'${Headers.sqlRowid}': ${Headers.sqlRowid} ?? 0,"], padding: Headers.parameterIntent);
    generatorIO.add(["'${Headers.parentRowId}': ${Headers.parentRowId} ?? 0,"], padding: Headers.parameterIntent);
    generatorIO.add(["'${Headers.parentClassName}': ${Headers.parentClassName} ?? '',"], padding: Headers.parameterIntent);
    List<String> toJsonList = List();
    final tablename = generatorIO.rootFileName;
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: tablename);
    for (DBRecord record in columnRecords) {
      final column = ColumnDeclarations(record: record);
      if (record.columnType == ColumnTypes.clazz) {
        toJsonList.add("'${column.columnName}': ${column.columnName}.toJson(),");
        continue;
      }
      if (record.columnType == ColumnTypes.array) {
        toJsonList.add("'${column.columnName}': jsonArray<${column.targetName}>(${column.columnName}),");
        continue;
      }
      toJsonList.add("'${column.columnName}': ${column.columnName},");
    }
    generatorIO.add(toJsonList, padding: Headers.parameterIntent);
    generatorIO.add(['};'], padding: Headers.classIndent);
    return null;
  }

  /// For created a class based on json object (Map<String,dynamic) that includes private properties of parent row id,
  /// and parent class name. With these extended properties it is possible to save/read/update to the on-device sql-store.
  Future<void> factoryFromJson() async {
    final tablename = generatorIO.rootFileName;
    generatorIO.newSection(
        name: '///- Factory fromJson',
        body: ['factory $tablename.fromJson(Map<String, dynamic> json) { '],
        padding: Headers.classIndent);
    generatorIO.add(['var _instance = ${generatorIO.rootFileName}('], padding: Headers.levelIndent(2));
    generatorIO.add([
      "${Headers.sqlRowid} : json['${Headers.sqlRowid}'] ?? 0,",
      "${Headers.parentRowId} : json['${Headers.parentRowId}'] ?? 0,",
      "${Headers.parentClassName} : json['${Headers.parentClassName}'] ?? '',",
    ], padding: Headers.levelIndent(3));
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: tablename);
    for (DBRecord record in columnRecords) {
      final column = ColumnDeclarations(record: record);
      if (record.columnType == ColumnTypes.array) {
        generatorIO.add([
          "${column.columnName} : json['${column.columnName}'].cast<Map<String,dynamic>>(),",
        ], padding: Headers.levelIndent(3));
      } else {
        generatorIO.add([
          "${column.columnName} : json['${column.columnName}'],",
        ], padding: Headers.levelIndent(3));
      }
    }
    generatorIO.add([');', 'return _instance;'], padding: Headers.levelIndent(2));
    generatorIO.add(['}'], padding: Headers.classIndent);
  }

  /// Objects from a server (via HTTP-GET) may have key names that do not map to properties within a class (case sensitivity, or
  /// json object is a another object (aka non-primitive int, double, string , or and array of objects), this factory will
  /// use the mapping from 'json' to 'field' from the editor to create an object.
  Future<void> factoryFromJsonCloud() async {
    final tablename = generatorIO.rootFileName;
    generatorIO.newSection(
        name: '///- Factory from Cloud',
        body: [
          'factory $tablename.fromCloud(Map<String, dynamic> json) { ',
        ],
        padding: Headers.classIndent);
    generatorIO.add(['var _instance = ${generatorIO.rootFileName}('], padding: Headers.levelIndent(2));
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: tablename);
    for (DBRecord record in columnRecords) {
      final column = ColumnDeclarations(record: record);
      generatorIO.add(["${column.columnName} : json['${record.json}'],"], padding: Headers.levelIndent(3));
    }
    generatorIO.add([');', 'return _instance;'], padding: Headers.levelIndent(2));
    generatorIO.add(['}'], padding: Headers.classIndent);
  }
}
