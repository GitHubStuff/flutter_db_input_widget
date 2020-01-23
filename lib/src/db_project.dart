import 'dart:io' as io;

import 'package:path_provider/path_provider.dart';

class DBProject {
  final String projectName;
  DBProject(this.projectName) : assert(projectName != null && projectName.isNotEmpty);

  Future<String> get _path async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<io.File> get _file async {
    final name = await _name;
    return io.File(name);
  }

  Future<String> get _name async {
    final path = await _path;
    return ('$path/$projectName.json');
  }

  Future<String> loadProject() async {
    try {
      io.File file = await _file;
      String content = await file.readAsString();
      return content;
    } catch (e) {
      return '';
    }
  }

  Future<void> saveProject({String contents}) async {
    final file = await _file;
    file.writeAsString(contents, flush: true);
  }
}
