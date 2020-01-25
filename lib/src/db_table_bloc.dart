//import 'package:flutter/material.dart';
//import 'package:flutter_db_input_widget/model/db_record.dart';
//import 'package:flutter_db_input_widget/model/db_table_json.dart';
//import 'package:flutter_db_input_widget/src/broadcast_stream.dart';
//import 'package:flutter_db_input_widget/src/field_input.dart';
//
//
//class DBTableBloc with JsonData {
//  final String name;
//  DBTableJson _dbTableJson;
//
//  DBTableBloc({@required this.name}) : assert(name != null && name.isNotEmpty) {
//    _dbTableJson = DBTableJson(tableName: name);
//  }
//
//  String addInput(FieldInput fieldInput) {
//    final validation = fieldInput.validate();
//    if (validation != null) return validation;
//    final record = DBRecord.from(tableName: name, fieldInput: fieldInput);
//    _dbTableJson.add(record);
//    return null;
//  }
//
//  Map<String, dynamic> toJson() => _dbTableJson.toJson();
//}
