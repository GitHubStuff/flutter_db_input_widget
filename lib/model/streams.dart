import 'package:flutter_abstract_package/flutter_abstract_package.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';

/// A broadcast stream to handle when a complete field/column description has been completed
class InputCompleteStream extends BroadcastStream<FieldInput> {
  @override
  void dispose() {
    close();
  }
}

/// A broadcast stream to handle pre-loading the ui input fields with an existing field/column description
class InputSelectedStream extends BroadcastStream<DBRecord> {
  @override
  void dispose() {
    close();
  }
}

class NameStream extends BroadcastStream<String> {
  @override
  void dispose() {
    close();
  }
}
