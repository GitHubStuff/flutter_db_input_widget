import 'dart:io' as io;

import 'package:flutter_db_input_widget/generation/generation_helpers.dart';
import 'package:flutter_tracers/trace.dart' as Log;
import 'package:path_provider/path_provider.dart';

/// Handles the read/write operates to the documents directory.
/// Load project will read the contents (if any) and return them or blank on first read
/// Write will push a string to the file (overwriting any existing data)
class DBProjectIO {
  final String projectName;
  final String fileSuffix;
  String get fileName => '$projectName.$fileSuffix';

  /// Creates an instance will the file name prefix and suffix that will be used.
  DBProjectIO(this.projectName, {this.fileSuffix = '.json'}) : assert(projectName != null && projectName.isNotEmpty);

  /// Helper to get the path
  Future<String> get _path async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Helper to get the file pointer
  Future<io.File> get _file async {
    final name = await _name;
    return io.File(name);
  }

  /// Create the file name from the system path and the user provided file name
  Future<String> get _name async {
    final path = await _path;
    String suffix = fileSuffix ?? '';
    return ('$path/$projectName$suffix');
  }

  /// Reads the contents of the file, if there is no file, then return ''
  Future<String> loadProject() async {
    try {
      io.File file = await _file;
      String content = await file.readAsString();
      return content;
    } catch (e) {
      /// If the file was not found, return an empty string and file creation will occur on write,
      /// as it assumed no file is a new project, no testing for other i/o issues (permission,locking, etc)
      /// is not done.
      return '';
    }
  }

  /// Write a string to file and closes it and flushes the buffer.
  Future<void> writeProject({String contents}) async {
    try {
      final file = await _file;
      file.writeAsString(contents, flush: true);
    } catch (error) {
      Log.e('writeProject: ${error.toString()}');
      throw FailedToWrite('writeProject: ${error.toString()}', BadWrite);
    }
  }
}
