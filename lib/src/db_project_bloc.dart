import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/io/db_project_io.dart' as File;
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_db_input_widget/src/broadcast_stream.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;

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

  /// Most of the creation process is async so this async helper method should be used to
  /// create the instance of the class. It also insures that if the project info exists on
  /// the device the data is loaded, or created if a new project.
  static Future<DBProjectBloc> make(String projectName) async {
    assert(projectName != null && projectName.isNotEmpty, 'Must have non-Null, non-empty project name');
    projectName = Strings.capitalize(projectName);
    final build = DBProjectBloc(name: projectName);
    final content = await build._dbProjectIO.loadProject();
    if (content.isEmpty) return build;
    final Map<String, dynamic> map = jsonDecode(content);
    return DBProjectBloc.fromJson(map);
  }

  /// File manager to read/write files to the local store.
  File.DBProjectIO _dbProjectIO;

  /// The list of tables, and field descriptions for all the tables used within a single app
  List<DBRecord> _tables = List();

  ///* Getters
  String get asLibraryRootName => '${Headers.libraryPrefix}$filename${Headers.librarySuffix}';
  String get filename => Strings.flutterFilenameStyle(using: name);

  /// The umbrellas name of the project, it serves as the root name of the .json file
  /// created with the table and fields blueprints.
  final String name;

  /// Constructor
  DBProjectBloc({this.name}) : assert(name != null && name.isNotEmpty) {
    _dbProjectIO = File.DBProjectIO(name);
  }

  /// Create a string that has the path
  String pathForTable(String tablename) {
    final asFlutterFilename = Strings.flutterFilenameStyle(using: tablename);
    final result = "/table_$asFlutterFilename/$asFlutterFilename${Headers.suffix}";
    return result;
  }

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

  List<DBRecord> columnsInTable({String name}) {
    var subset = _tables.where((rec) => rec.name.toLowerCase() == name.toLowerCase()).toList()
      ..sort((a, b) => a.field.toLowerCase().compareTo(b.field.toLowerCase()));
    return subset;
  }

  /// Get just the list of table names. These are needed for code generation.
  List<String> tableNameList() {
    List<String> result = List();
    final temp = sortedTableList();
    String currentName;
    for (DBRecord record in temp) {
      if (record.name.toLowerCase() != currentName) result.add(record.name);
      currentName = record.name.toLowerCase();
    }
    return result;
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

  /// Create a list of flutter DataRow widgets to display the list of tables/fields have been entered.
  List<DataRow> dataRows(
    BuildContext context, {
    @required String preferTable,
    @required Sink<DBRecord> sink,
    @required TextStyle style,
  }) {
    List<DataRow> rows = List();
    List<DBRecord> records = sortedTableList(preferTable);
    for (int i = 0; i < records.length; i++) {
      final row = records[i].dataCells(context, index: i, sink: sink, style: style);
      rows.add(DataRow(cells: row));
    }
    return rows;
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

  /// When the user selects a row, that row is moved into the edit fields and removed from the list (a way to delete a row/field)
  int remove({@required DBRecord dbRecord}) {
    assert(dbRecord != null);
    final field = dbRecord.field;
    final table = dbRecord.name;
    final index = find(field: field, inTable: table);
    assert(index != null && index >= 0 && index < _tables.length);
    _tables.removeAt(index);
    return _tables.length;
  }

  /// Write the collected table information to the {projectName}.json file.
  Future<void> writeTablesToFile({@required bool prettyPrint}) async {
    _tables.sort((a, b) => (a.name + a.field).toLowerCase().compareTo((b.name + b.field).toLowerCase()));
    String data = dataString(prettyPrint: prettyPrint ?? false);
    await _dbProjectIO.writeProject(contents: data);
  }
}
