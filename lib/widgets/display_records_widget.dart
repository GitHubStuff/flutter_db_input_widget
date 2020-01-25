import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tracers/trace.dart' as Log;

class DisplayRecordsWidget extends StatefulWidget {
  const DisplayRecordsWidget({Key key}) : super(key: key);
  static const route = '/displayRecordsWidget';

  @override
  _DisplayWidget createState() => _DisplayWidget();
}

class _DisplayWidget extends State<DisplayRecordsWidget> with WidgetsBindingObserver, AfterLayoutMixin<DisplayRecordsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Log.t('displayRecordsWidget initState');
  }

  @override
  void afterFirstLayout(BuildContext context) {
    Log.t('displayRecordsWidget afterFirstLayout');
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    Log.t('displayRecordsWidget didChangeDependencies');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Log.t('displayRecordsWidget didChangeAppLifecycleState ${state.toString()}');
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness = WidgetsBinding.instance.window.platformBrightness;
    Log.t('displayRecordsWidget didChangePlatformBrightness ${brightness.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    return body();
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    Log.t('displayRecordsWidget didUpdateWidget');
    super.didUpdateWidget(oldWidget);
  }

  @override
  void deactivate() {
    Log.t('displayRecordsWidget deactivate');
    super.deactivate();
  }

  @override
  void dispose() {
    Log.t('displayRecordsWidget dispose');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Scaffold body
  Widget body() {
    return Container(
      height: 200.0,
      child: ListView.builder(itemBuilder: (context, index) {
        return Text('Index $index');
      }),
    );
  }
}
