import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_db_input_widget/src/broadcast_stream.dart';

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
