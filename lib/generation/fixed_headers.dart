import 'package:intl/intl.dart' as INTL;

const String _fileHeader = '''
/// AUTO-GENERATED CODE - DO NOT MODIFY IF POSSIBLE
/// Created: [DATE]

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_sqlite_controller/flutter_sqlite_controller.dart' as DB;
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

/// Constants used in composing file names, as these are shared across creating various files
/// they are fixed any changes to how names are done requires just changing these.
const columnPrefix = 'column';
const libraryPrefix = 'sqlite_';
const librarySuffix = '_library';
const tablePrefix = 'table_';

const int classIndent = 3;
const int parameterIntent = 7;
const int trailingComment = 5;
