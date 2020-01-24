import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_theme_package/flutter_theme_package.dart';
import 'package:flutter_tracers/trace.dart' as Log;
import 'package:notifier/notifier_provider.dart';

void main() {
  runApp(NotifierProvider(
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModeTheme(
      data: (brightness) => (brightness == Brightness.light) ? ModeThemeData.bright() : ModeThemeData.dark(),
      defaultBrightness: Brightness.light,
      themedWidgetBuilder: (context, theme) {
        return MaterialApp(
          home: Example(),
          initialRoute: '/',
          routes: {
            Example.route: (context) => MyApp(),
          },
          theme: theme,
          title: 'Example Demo',
        );
      },
    );
  }
}

class Example extends StatefulWidget {
  const Example({Key key}) : super(key: key);
  static const route = '/example';

  @override
  _Example createState() => _Example();
}

class _Example extends State<Example> with WidgetsBindingObserver, AfterLayoutMixin<Example> {
  bool _hideSpinner = true;

  TabletInputLine _tabletInputLine;
  FieldInfoStream _fieldInfoStream = FieldInfoStream();
  FieldInfo _fieldInfo = FieldInfo()..mock(complex: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Log.t('example initState');
    _tabletInputLine = TabletInputLine(
      fieldInfoStream: _fieldInfoStream,
      fieldInfo: _fieldInfo,
    );
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    Log.t('example didChangeDependencies');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Log.t('example didChangeAppLifecycleState ${state.toString()}');
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness = WidgetsBinding.instance.window.platformBrightness;
    ModeTheme.of(context).setBrightness(brightness);
    Log.t('example didChangePlatformBrightness ${brightness.toString()}');
  }

  @override
  void afterFirstLayout(BuildContext context) {
    Log.t('example afterFirstLayout');
    listener();
  }

  @override
  Widget build(BuildContext context) {
    Log.t('example build');
    return HudScaffold.progressText(
      context,
      hide: _hideSpinner,
      indicatorColors: Swatch(bright: Colors.purpleAccent, dark: Colors.greenAccent),
      progressText: 'Example Showable spinner',
      scaffold: Scaffold(
        appBar: AppBar(
          title: Text('Title: example'),
        ),
        body: body(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _hideSpinner = false;
              Future.delayed(Duration(seconds: 3), () {
                setState(() {
                  _hideSpinner = true;
                });
              });
            });
          },
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    Log.t('example didUpdateWidget');
    super.didUpdateWidget(oldWidget);
  }

  @override
  void deactivate() {
    Log.t('example deactivate');
    super.deactivate();
  }

  @override
  void dispose() {
    Log.t('example dispose');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Scaffold body
  Widget body() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _tabletInputLine,
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: WideAnimatedButton(
                caption: 'Write',
                colors: ModeThemeData.productSwatch,
                height: 60.0,
                width: 200,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: WideAnimatedButton(
                caption: 'Read',
                colors: ModeThemeData.primarySwatch,
                height: 60.0,
                width: 200.0,
              ),
            ),
          ],
        )
      ],
    ));
  }

  void listener() {
    _fieldInfoStream.stream.listen((event) {
      Log.t(event.toString());
    });
  }
}
