import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/src/broadcast_stream.dart';
import 'package:flutter_db_input_widget/src/field_input.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;
import 'package:flutter_theme_package/flutter_theme_package.dart' as UI;

/// This class represents the information that is used to generate dart code for tables and fields
/// in the table. Arrays of this class are stored in .json text files to serve as the blue-print
/// for the generated .dart code.
///   name - the name of the sqlite table
///   field - the name of the column in the sqlite database
///   json - the key of an incoming json string that is used to map to the name (keys in json files are often not camel-case,
///          name mapping should be applied {eg: "ID":"456" should map to sqlite column 'userId'})
///   type - data type of the sqlite column:
///           a : array
///           b : bool
///           c : class
///           d : dateTime
///           i : int
///           r : real (aka double)
///           s : string
///   comment - Text of comments that will within the generated code as a way of documenting
///
class DBRecord with JsonData {
  /// Json string key names, used to prevent typo's when using quoted strings
  static const _name = 'name';
  static const _field = 'field';
  static const _json = 'json';
  static const _type = 'type';
  static const _target = 'target';
  static const _comment = 'comment';

  final String name;
  final String field;
  final String json;
  final String type;
  final String target;
  final String comment;
  DBRecord._private(this.name, this.field, this.json, this.type, this.target, this.comment)
      : assert(name != null),
        assert(field != null),
        assert(json != null),
        assert(type != null),
        assert(target != null),
        assert(comment != null);

  factory DBRecord.from({@required String tableName, @required FieldInput fieldInput}) {
    assert(fieldInput != null);
    final input = fieldInput;
    return DBRecord._private(tableName, input.field, input.json, input.type, input.target ?? '', input.comment);
  }

  DBRecord.fromJson(Map map)
      : name = map[_name],
        field = map[_field],
        json = map[_json],
        type = map[_type],
        target = map[_target],
        comment = map[_comment];

  Map<String, dynamic> toJson() => {
        _name: name,
        _field: field,
        _json: json,
        _type: type,
        _target: target,
        _comment: comment,
      };

  static DBRecord mock([String table = 'MockTable']) {
    final field = 'J' + DateTime.now().toLocal().toIso8601String().substring(20);
    var result = DBRecord._private('$table', '$field', 'mockJson', 'c', 'mockTarget', 'mockComment');
    return result;
  }

  static List<DataColumn> dataColumns(BuildContext context) {
    TextStyle textStyle = TextStyle(fontSize: UI.getTextSizes(UI.TextSizes.display1));
    List<DataColumn> columns = List();
    columns.add(DataColumn(label: Text('Select', style: textStyle)));
    columns.add(DataColumn(label: Text('Table', style: textStyle)));
    columns.add(DataColumn(label: Text('Field', style: textStyle)));
    columns.add(DataColumn(label: Text('Json', style: textStyle)));
    columns.add(DataColumn(label: Text('Type', style: textStyle)));
    columns.add(DataColumn(label: Text('Target', style: textStyle)));
    columns.add(DataColumn(label: Text('Comment', style: textStyle)));
    return columns;
  }

  String get asTrailingComment => Strings.intent(formattedComment, Headers.trailingComment);
  String get formattedComment => (comment.trim().isEmpty) ? '' : '/// ${comment.trim()}';

  List<DataCell> dataCells(
    BuildContext context, {
    @required int index,
    @required Sink<DBRecord> sink,
    @required TextStyle style,
  }) {
    assert(sink != null);
    style ??= TextStyle(fontSize: UI.getTextSizes(UI.TextSizes.headline));
    List<DataCell> cells = List();
    final button = IconButton(
      icon: Icon(
        Icons.adjust,
        size: 44.0,
        semanticLabel: 'Adjust',
      ),
      onPressed: () {
        sink.add(this);
      },
    );
    cells.add(DataCell(button));
    cells.add(DataCell(Text(name, style: style)));
    cells.add(DataCell(Text(field, style: style)));
    cells.add(DataCell(Text(json, style: style)));
    cells.add(DataCell(Text(typeDetail(), style: style)));
    cells.add(DataCell(Text(target, style: style)));
    cells.add(DataCell(Text(comment, style: style)));
    return cells;
  }

  String typeDetail() {
    switch (type) {
      case 'a':
        return 'array';
      case 'b':
        return 'bool';
      case 'c':
        return 'class';
      case 'd':
        return 'date';
      case 'i':
        return 'int';
      case 'r':
        return 'double/float';
      case 's':
        return 'string';
      default:
        throw Exception('Cannot detail type <$type>');
    }
  }
}
