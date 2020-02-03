import 'package:intl/intl.dart' as INTL;

const String _fileHeader = '''
/// AUTO-GENERATED CODE - DO NOT MODIFY IF POSSIBLE
/// Created: [DATE]

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_sqlite_controller/flutter_sqlite_controller.dart' as SQL;
import 'package:flutter_tracers/trace.dart' as Log;
''';

String libraryHeader() {
  final heading = '''
/// AUTO-GENERATED CODE - DO NOT MODIFY IF POSSIBLE
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

String arrayFactory(String classname, String targetName) {
  final code = '''
  factory $classname.fromArray([Map<String, dynamic> data, int parentId = 0) {
    for (Map<String, dynamic> item in data) {
       if ((item['$parentRowId'] ?? 0) == 0) {
         item['$parentRowId'] = parentId;
         $targetName.fromJson(item);
       }
    }
  }
''';
  return code;
}

String arrayMaker(String classname) {
  final code = '''
  
  /// Creates a List<$classname> to translate and json-array to array of $classname
  static List<$classname> usingJsonArray(List<Map<String, dynamic>> jsonArray) {
     List<$classname> result = List();
     for (Map<String, dynamic> json in jsonArray) {
        final value = (json is $classname) ? json : $classname.fromJson(json);
        result.add(value);
     }
     return result;
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
const String sqlRowid = 'rowid';
const String suffix = '.g.txt';

int levelIndent(int level) => (classIndent + 2 * level);
