class FieldJson {
  String name;
  String field;
  String json;
  String type;
  String target;
  String comment;

  Map<String, dynamic> toJson() => {
        'name': name,
        'field': field,
        'json': json,
        'type': type,
        'target': target,
        'comment': comment,
      };

  static FieldJson mock() {
    var result = FieldJson();
    result.name = 'mock';
    result.field = 'mock field';
    result.json = 'mock json';
    result.type = 'c';
    result.target = 'mockTarget';
    result.comment = 'mock comment';
    return result;
  }
}
