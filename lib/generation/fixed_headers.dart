import 'package:intl/intl.dart' as INTL;

const String _fileHeader = '''/// AUTO-GENERATED CODE - DO NOT MODIFY IF POSSIBLE
/// Created: [DATE]

//import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_sqlite_controller/flutter_sqlite_controller.dart' as SQL;
//import 'package:flutter_tracers/trace.dart' as Log;''';

String libraryHeader() {
  final heading = '''/// AUTO-GENERATED CODE - DO NOT MODIFY IF POSSIBLE
/// Created: [DATE]
''';
  final timestamp = INTL.DateFormat('MMMM dd,yyyy HH:mm').format(DateTime.now().toUtc()) + '(utc)';
  final result = heading.replaceFirst('[DATE]', timestamp);
  return result;
}

String tableHeader() {
  final timestamp = INTL.DateFormat('MMMM dd,yyyy HH:mm').format(DateTime.now().toUtc()) + '(utc)';
  final result = _fileHeader.replaceFirst('[DATE]', timestamp);
  return result;
}

String createStaticBuilders(String classname) {
  final code = '''
  static $classname build(dynamic data) {
    if (data == null) return null;
    if (data is Map) return $classname.fromJson(data);
    if (data is $classname) return data;
    throw Exception('static ${classname}Build could not parse: \${data.toString()}');
  }
  
  ///- buildArray
  static List<$classname> buildArray(List<dynamic> array) {
    List<$classname> result = List();
    if (array is List<Map<String,dynamic>>) {
      for (Map<String,dynamic> item in array) {
         result.add($classname.fromJson(item));
      }
      return result;
    }
    if (array is List<$classname>) {
      for ($classname item in array) {
         result.add(item);
      }
      return result;
    }
    throw Exception('Unknown datatype \$array');
  }
''';
  return code;
}

/// Constants used in composing file names, as these are shared across creating various files
/// they are fixed any changes to how names are done requires just changing these.
const columnPrefix = 'column';
const libraryPrefix = 'sqlite_';
const librarySuffix = '_library';
const tablePrefix = 'table_';

const int classIndent = 3;
const int parameterIntent = 7;
const int trailingComment = 5;

const String parentRowId = 'parentRowId';
const String parentClassName = 'parentClassName';
const String sqlRowid = 'rowid';
const String suffix = '.g.txt';

int levelIndent(int level) => (classIndent + 2 * level);
