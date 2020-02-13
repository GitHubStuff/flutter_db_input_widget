import 'package:flutter_db_input_widget/generation/column_declarations.dart';
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
        name: '///- *Create* object from SQL',
        body: ['static Future<int> create(SQLiteLink link) async {'],
        padding: Headers.classIndent);
    generatorIO.add(['setParentRowId(parentRow);'], padding: Headers.classIndent + 3);
    generatorIO.add(['await createRecord();'], padding: Headers.classIndent + 3);

    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    for (DBRecord record in columnRecords) {
      if (record.columnType == ColumnTypes.array || record.columnType == ColumnTypes.clazz) {
        generatorIO.add(['await ${record.target}.createObject(rowid, parentName);'], padding: Headers.classIndent + 3);
      }
    }
    generatorIO.add(['}'], padding: Headers.classIndent + 3);
    return null;
  }

  Future<void> readObjectMethod() {
    generatorIO.newSection(
        name: '///- Read Object from SQL',
        body: ["static Future<List<${generatorIO.rootFileName}>> readObject({String where, String orderBy = 'rowid'}) async {"],
        padding: Headers.classIndent);
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    generatorIO.add([
      'List<${generatorIO.rootFileName}> results = await ${generatorIO.rootFileName}.readPartialRecord(where: where);',
      'for (${generatorIO.rootFileName} item in results) {',
      "   final subWhere = \'(parentRowId = \${item.rowid} AND parentClassName = \$${generatorIO.rootFileName}\';",
    ], padding: Headers.classIndent + 3);
    for (DBRecord column in columnRecords) {
      final ColumnDeclarations declarations = ColumnDeclarations(record: column);
      if (column.columnType == ColumnTypes.array || column.columnType == ColumnTypes.clazz) {
        generatorIO.add([
          '   List<${column.target}> _${column.target} = await ${column.target}.readObject(where: "\$subWhere", orderBy: orderBy);',
        ], padding: Headers.classIndent + 3);
        if (column.columnType == ColumnTypes.array) {
          generatorIO.add(['item.set${declarations.columnSetter}(objects);'], padding: Headers.classIndent + 3);
        } else {
          generatorIO.add(['item.set${declarations.columnSetter}(objects[0]);'], padding: Headers.classIndent + 3);
        }
      }
      generatorIO.add(['  }', 'return results;', '}'], padding: Headers.classIndent + 3);
    }
    return null;
  }
}
