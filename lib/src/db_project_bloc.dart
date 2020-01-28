import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/io/db_project_io.dart' as File;
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_db_input_widget/src/broadcast_stream.dart';

import '../flutter_db_input_widget.dart';

/// A Project bloc {bloc = Business LOgiC} is the wrapper/gateway to allow
/// a code build of fields for all the tables used within a single app (aka project)
/// Fields are defined in the UI-layer and table/fields information is passed to
/// this class where they are loaded/stored/written/saved on device or generated into
/// dart code.
///
class DBProjectBloc with JsonData {
  /// Used as keys in for json text to avoid typo's when using literal strings
  static const _Name = 'name';
  static const _Tables = 'tables';

  /// The umbrellas name of the project, it serves as the root name of the .json file
  /// created with the table and fields blueprints.
  final String name;

  /// The list of tables, and field descriptions for all the tables used within a single app
  List<DBRecord> _tables = List();

  int get tableCount => _tables.length;

  /// Providing a table name will keep records of that table at the top of the list, good when
  /// the UI is showing most recently added fields
  List<DBRecord> sortedTableList([String selectedTable = '']) {
    final fav = (selectedTable ?? '').toLowerCase();
    List<DBRecord> temp = List.from(_tables);
    temp.sort((a, b) {
      final aKey = (a.name.toLowerCase() == fav) ? '0' + a.name : '1' + a.name;
      final bKey = (b.name.toLowerCase() == fav) ? '0' + b.name : '1' + b.name;
      return (aKey + a.field).toLowerCase().compareTo((bKey + b.field).toLowerCase());
    });

    return temp;
  }

  /// File manager to read/write files to the local store.
  File.DBProjectIO _dbProjectIO;

  DBProjectBloc({this.name}) : assert(name != null && name.isNotEmpty) {
    _dbProjectIO = File.DBProjectIO(name);
  }

  /// Most of the creation process is async so this async helper method should be used to
  /// create the instance of the class. It also insures that if the project info exists on
  /// the device the data is loaded, or created if a new project.
  static Future<DBProjectBloc> make(String projectName) async {
    assert(projectName != null && projectName.isNotEmpty, 'Must have non-Null, non-empty project name');
    final build = DBProjectBloc(name: projectName);
    final content = await build._dbProjectIO.loadProject();
    if (content.isEmpty) return build;
    final Map<String, dynamic> map = jsonDecode(content);
    return DBProjectBloc.fromJson(map);
  }

  /// Factory method where .json file from the local store that has been converted into a Map
  /// can be used to create an instance of the project
  factory DBProjectBloc.fromJson(Map<String, dynamic> map) {
    final result = DBProjectBloc(name: map[_Name]);
    final tables = map[_Tables];
    result._tables = (tables as List).map((item) => DBRecord.fromJson(item)).toList();
    return result;
  }

  /// This map, converted to string, will be the content of the .json file stored on device.
  @override
  Map<String, dynamic> toJson() => {
        _Name: name,
        _Tables: _tables,
      };

  /// Data from the UI with the design of a column of a database table is passed in
  /// and either updated or added to the list of table/column info.
  void add({@required FieldInput fieldInput, @required String toTable}) {
    assert(fieldInput != null);
    assert(toTable != null && toTable.isNotEmpty);
    int index = find(field: fieldInput.field, inTable: toTable);

    /// Put the field information in class with its parent table information and replace
    /// or add it to the list
    final record = DBRecord.from(tableName: toTable, fieldInput: fieldInput);
    if (index != null) {
      _tables[index] = record;
    } else {
      _tables.add(record);
    }
  }

  /// Uniqueness is a database is a unique column name within a table,
  /// This looks for instances of a field name within the list of table information with
  /// matches on both the table name and in the column name. This controls if an item
  /// is being added or updated.
  int find({@required String field, String inTable}) {
    for (int i = 0; i < _tables.length; i++) {
      final table = _tables[i];
      if (table.name.toLowerCase() == inTable.toLowerCase() && table.field.toLowerCase() == field.toLowerCase()) return i;
    }
    return null;
  }

  /// Write the collected table information to the {projectName}.json file.
  Future<void> writeTablesToFile({@required bool prettyPrint}) async {
    _tables.sort((a, b) => (a.name + a.field).toLowerCase().compareTo((b.name + b.field).toLowerCase()));
    String data = dataString(prettyPrint: prettyPrint ?? false);
    await _dbProjectIO.writeProject(contents: data);
  }

  List<DataRow> dataRows(BuildContext context,
      {@required String preferTable, @required Sink<DBRecord> sink, @required TextStyle style}) {
    List<DataRow> rows = List();
    List<DBRecord> records = sortedTableList(preferTable);
    for (int i = 0; i < records.length; i++) {
      final row = records[i].dataCells(context, index: i, sink: sink, style: style);
      rows.add(DataRow(cells: row));
    }
    return rows;
  }
}
