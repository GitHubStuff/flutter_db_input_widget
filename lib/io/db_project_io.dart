import 'dart:io' as IO;

import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/generation/generation_helpers.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;
import 'package:flutter_tracers/trace.dart' as Log;
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';

/// Handles the read/write operates to the documents directory.
/// Load project will read the contents (if any) and return them or blank on first read
/// Write will push a string to the file (overwriting any existing data)
///
class GeneratorIO extends DBProjectIO {
  final String rootFileName;
  GeneratorIO({this.rootFileName, String suffix = '.g.dart'}) : super(rootFileName, fileSuffix: suffix);
  List<String> _lines = List();

  /// Getters
  void get blankLine => _lines.add('\n');
  String get content => _lines.join();

  /// Methods
  int add(List<String> lines, {int padding = 0}) {
    assert(lines != null);
    assert(padding >= 0);
    var result = lines.map((e) => '${Strings.indent(e, padding)}\n').toList();
    _lines.addAll(result);
    return _lines.length;
  }

  void newSection({String name, List<String> body, int padding = 0}) {
    blankLine;
    if (name != null) add([name.startsWith('//') ? name : '/// $name'], padding: padding);
    if (body != null) add(body, padding: padding);
  }

  Future<void> write(String content) async {
    await writeProject(contents: content);
  }

  Future<dynamic> createTableFilePath({DBProjectBloc dbProjectBloc}) async {
    final libraryPath = 'tables';
    final tablePath = 'table_$filename';
    final tableFilename = '$filename$fileSuffix';
    try {
      final root = await _path;
      final path = Path.join(root, libraryPath, tablePath, tableFilename);
      if (!await IO.Directory(Path.dirname(path)).exists()) {
        await IO.Directory(Path.dirname(path)).create(recursive: true);
      }
      return path;
    } catch (error) {
      Log.e('db_project_io (error): ${error.toString()}');
      throw CannotCreateTableFilePath('db_project_io ${error.toString()}', HelperErrors.createTableFilePath);
    }
  }
}

///*************************

class DBProjectIO {
  final String projectName;
  final String fileSuffix;
  String get filename => Strings.flutterFilenameStyle(using: projectName);

  /// Creates an instance will the file name prefix and suffix that will be used.
  DBProjectIO(this.projectName, {this.fileSuffix = '.json'}) : assert(projectName != null && projectName.isNotEmpty);

  /// Helper to get the path
  Future<String> get _path async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Helper to get the file pointer
  Future<IO.File> get _file async {
    final name = await _name;
    return IO.File(name);
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
      IO.File file = await _file;
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
      await file.writeAsString(contents, flush: true);
    } catch (error) {
      Log.e('writeProject (error): ${error.toString()}');
      throw FailedToWrite('writeProject: ${error.toString()}', HelperErrors.badWrite);
    }
  }
}
