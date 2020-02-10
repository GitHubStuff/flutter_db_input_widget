import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/io/db_project_io.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';

import '../flutter_db_input_widget.dart';
import 'generator.dart';

class ObjectCRUD {
  final Callback callback;
  final GeneratorIO generatorIO;
  final DBProjectBloc projectBloc;
  ObjectCRUD({this.callback, this.generatorIO, this.projectBloc});

  Future<void> createObjectMethod() {
    generatorIO.newSection(
        name: '/- Create object from SQL',
        body: ['Future<void> createObject(int parentRow, String parentName) async {'],
        padding: Headers.classIndent);
    generatorIO.add(['setParentRowId(parentRow, parentName)'], padding: Headers.classIndent + 3);
    generatorIO.add(['await createRecord();'], padding: Headers.classIndent + 3);

    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    for (DBRecord record in columnRecords) {
      if (record.columnType == ColumnTypes.array || record.columnType == ColumnTypes.clazz) {
        generatorIO.add(['await ${record.field}.createObject(rowid, parentName);'], padding: Headers.classIndent + 3);
      }
    }
    return null;
  }

  Future<void> readObjectMethod() {
    generatorIO.newSection(
        name: '/- Read Object from SQL',
        body: ['Future<void> readObject(int parentRow, String parentName) async {'],
        padding: Headers.classIndent);
    generatorIO.add([''], padding: Headers.classIndent + 3);
    return null;
  }
}
