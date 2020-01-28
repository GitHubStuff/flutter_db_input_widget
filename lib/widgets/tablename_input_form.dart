import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_tracers/trace.dart' as Log;

class NameInputForm extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Sink<String> sink;
  final String fieldName;
  final String title;
  const NameInputForm(
      {Key key,
      @required this.controller,
      @required this.focusNode,
      @required this.sink,
      @required this.fieldName,
      @required this.title})
      : assert(sink != null),
        super(key: key);

  @override
  _NameInputForm createState() => _NameInputForm();
}

class _NameInputForm extends State<NameInputForm> with WidgetsBindingObserver, AfterLayoutMixin<NameInputForm> {
  // ignore: non_constant_identifier_names
  Size get ScreenSize => MediaQuery.of(context).size;
  final formKey = GlobalKey<FormState>();
  TextEditingController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Log.t('nameInputForm initState()');
    controller = widget.controller ?? TextEditingController();
    controller.text = widget.fieldName;
  }

  @override
  void afterFirstLayout(BuildContext context) {
    Log.t('nameInputForm afterFirstLayout()');
    setFocus();
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    Log.t('nameInputForm didChangeDependencies()');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Log.t('nameInputForm didChangeAppLifecycleState ${state.toString()}');
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness = WidgetsBinding.instance.window.platformBrightness;
    Log.t('nameInputForm didChangePlatformBrightness ${brightness.toString()}');
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    Log.t('nameInputForm didUpdateWidget()');
    super.didUpdateWidget(oldWidget);
  }

  @override
  void deactivate() {
    Log.t('nameInputForm deactivate()');
    super.deactivate();
  }

  @override
  void dispose() {
    Log.t('nameInputForm dispose()');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Log.t('nameInputForm build()');
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
            return FieldInput.validateInputField(name: text.trim());
          },
        ),
        key: formKey);
  }

  /// Weird hack to get the keyboard to focus/appear on the first field of the form.
  void setFocus() {
    if (widget.focusNode == null) return;
    Log.t('nameInputForm getting focus');
    Future.delayed(Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(widget.focusNode);
      FocusScope.of(context).requestFocus(widget.focusNode);
    });
  }
}
