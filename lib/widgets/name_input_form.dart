import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_tracers/trace.dart' as Log;

class NameInputForm extends StatefulWidget {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final String formText;
  final String title;
  final void Function(String newName) result;
  NameInputForm({Key key, @required this.formText, @required this.title, @required this.result})
      : assert(title != null),
        assert(result != null),
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
    controller = widget.controller;
    controller.text = widget.formText;
  }

  @override
  void afterFirstLayout(BuildContext context) {
    Log.t('nameInputForm afterFirstLayout()');
    Log.f('Removed call to setFocus()');
    //setFocus();
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
          autofocus: false,
          controller: controller,
          decoration: InputDecoration(labelText: widget.title),
          enableSuggestions: false,
          focusNode: widget.focusNode,
          initialValue: null,
          onChanged: (string) {},
          onFieldSubmitted: (string) {
            if (formKey.currentState.validate()) {
              widget.result(string.trim());
            }
          },
          showCursor: true,
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
    Log.d('nameInputForm setFocus()');
    Future.delayed(Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(widget.focusNode);
      FocusScope.of(context).requestFocus(widget.focusNode);
    });
  }
}
