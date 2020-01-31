import 'package:intl/intl.dart' as INTL;

const String _fileHeader = ''''
/// AUTO-GENERATED CODE - DO NOT MODIFY IF POSSIBLE
/// Created: **
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_sqlite_controller/flutter_sqlite_controller.dart' as DB;
import 'package:flutter_tracers/trace.dart' as Log;

''';

String header() {
  final timestamp = INTL.DateFormat('MMM dd,YYYY HH:mm').format(DateTime.now().toUtc()) + '(utc)';
  final result = _fileHeader.replaceFirst('**', timestamp);
  return result;
}
