import 'field_json.dart';

class ProjectJson {
  List<FieldJson> project;

  Map<String, dynamic> toJson() => {
        'project': project,
      };

  static ProjectJson mock() {
    var result = ProjectJson();
    result.project.add(FieldJson.mock());
    result.project.add(FieldJson.mock());
    return result;
  }
}
