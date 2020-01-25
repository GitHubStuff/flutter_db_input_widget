//import 'package:flutter/material.dart';
//import 'package:flutter_db_input_widget/model/db_record.dart';
//
///// This is a class that wraps all the fields of a specific table.
///// It is the tableName and the list of fields associated with it.
//class DBTableJson {
//  final String tableName;
//  List<DBRecord> _project = List();
//
//  DBTableJson({@required this.tableName}) : assert(tableName != null && tableName.isNotEmpty);
//
//  /// And a field to the table
//  int add(DBRecord record) {
//    _project.add(record);
//    return _project.length;
//  }
//
//  /// Create a json object
//  Map<String, dynamic> toJson() => {
//        '$tableName': _project,
//      };
//
//  static DBTableJson mock() {
//    var result = DBTableJson(tableName: '~mock');
//    result.add(DBRecord.mock());
//    result.add(DBRecord.mock());
//    result.add(DBRecord.mock());
//    result.add(DBRecord.mock());
//    return result;
//  }
//}
