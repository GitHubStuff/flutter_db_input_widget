import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_tracers/trace.dart' as Log;

class TableNameInputForm extends StatefulWidget {
  final Sink<String> sink;
  final String tableName;
  final String title;
  const TableNameInputForm({Key key, @required this.sink, @required this.tableName, @required this.title})
      : assert(sink != null),
        super(key: key);

  @override
  _TableNameInputForm createState() => _TableNameInputForm();
}

class _TableNameInputForm extends State<TableNameInputForm> with WidgetsBindingObserver, AfterLayoutMixin<TableNameInputForm> {
  // ignore: non_constant_identifier_names
  Size get ScreenSize => MediaQuery.of(context).size;
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Log.t('tableNameInputForm initState()');
    controller.text = widget.tableName;
  }

  @override
  void afterFirstLayout(BuildContext context) {
    Log.t('tableNameInputForm afterFirstLayout()');
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    Log.t('tableNameInputForm didChangeDependencies()');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Log.t('tableNameInputForm didChangeAppLifecycleState ${state.toString()}');
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness = WidgetsBinding.instance.window.platformBrightness;
    Log.t('tableNameInputForm didChangePlatformBrightness ${brightness.toString()}');
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    Log.t('tableNameInputForm didUpdateWidget()');
    super.didUpdateWidget(oldWidget);
  }

  @override
  void deactivate() {
    Log.t('tableNameInputForm deactivate()');
    super.deactivate();
  }

  @override
  void dispose() {
    Log.t('tableNameInputForm dispose()');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Log.t('tableNameInputForm build()');
    return Form(
        child: TextFormField(
          autocorrect: false,
          controller: controller,
          decoration: InputDecoration(labelText: widget.title),
          enableSuggestions: false,
          focusNode: null,
          onChanged: (string) {},
          onFieldSubmitted: (string) {
            if (formKey.currentState.validate()) {
              widget.sink.add(string.trim());
            }
          },
          textInputAction: TextInputAction.done,
          validator: (text) {
            return FieldInput.validateTable(name: text.trim());
          },
        ),
        key: formKey);
  }
}
