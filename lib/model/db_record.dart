import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/src/broadcast_stream.dart';
import 'package:flutter_db_input_widget/src/field_input.dart';

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
  final String name;
  final String field;
  final String json;
  final String type;
  final String target;
  final String comment;
  DBRecord(this.name, this.field, this.json, this.type, this.target, this.comment)
      : assert(name != null),
        assert(field != null),
        assert(json != null),
        assert(type != null),
        assert(target != null),
        assert(comment != null);

  factory DBRecord.from({@required String tableName, @required FieldInput fieldInput}) {
    assert(fieldInput != null);
    final input = fieldInput;
    return DBRecord(tableName, input.field, input.json, input.type, input.target ?? '', input.comment);
  }

  DBRecord.fromJson(Map map)
      : name = map['name'],
        field = map['field'],
        json = map['json'],
        type = map['type'],
        target = map['target'],
        comment = map['comment'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'field': field,
        'json': json,
        'type': type,
        'target': target,
        'comment': comment,
      };

  static DBRecord mock([String table = 'MockTable']) {
    final field = 'J' + DateTime.now().toLocal().toIso8601String().substring(20);
    var result = DBRecord('$table', '$field', 'mockJson', 'c', 'mockTarget', 'mockComment');
    return result;
  }
}
