import 'dart:io' as io;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/generation/generation_helpers.dart';
import 'package:flutter_tracers/trace.dart' as Log;
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';

/// Handles the read/write operates to the documents directory.
/// Load project will read the contents (if any) and return them or blank on first read
/// Write will push a string to the file (overwriting any existing data)
///
class GeneratorIO extends DBProjectIO {
  GeneratorIO({String rootFileName, String suffix = '.g.dart'}) : super(rootFileName, fileSuffix: suffix);
  List<String> _lines = List();

  int add(List<String> lines, {int padding = 0}) {
    assert(lines != null);
    assert(padding >= 0);
    var result = lines.map((e) => '${e.padLeft(e.length + padding, " ")}\n').toList();
    _lines.addAll(result);
    return _lines.length;
  }

  String get content => _lines.join();

  Future<void> write(String content) async {
    await writeProject(contents: content);
  }

  Future<dynamic> createTableFilePath({@required String libraryPath, @required String tableFileName}) async {
    try {
      final root = await _path;
      final path = Path.join(root, libraryPath.toLowerCase(), tableFileName.toLowerCase());
      if (!await Directory(Path.dirname(path)).exists()) {
        await Directory(Path.dirname(path)).create(recursive: true);
      }
      return path;
    } catch (error) {
      Log.e('createTableFilePath error: ${error.toString()}');
      return error;
    }
  }
}

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
