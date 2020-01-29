import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_theme_package/flutter_theme_package.dart';
import 'package:flutter_tracers/trace.dart' as Log;
import 'package:keyboard_visibility/keyboard_visibility.dart';
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
  // ignore: non_constant_identifier_names
  Size get ScreenSize => MediaQuery.of(context).size;

  String caption = 'Start';
  FieldInput fieldInput = FieldInput();
  bool hideSpinner = true;
  InputCompleteStream inputCompleteStream = InputCompleteStream();
  InputSelectedStream inputSelectedStream = InputSelectedStream();
  KeyboardVisibilityNotification keyboardVisibilityNotification = KeyboardVisibilityNotification();
  double listHeight = 300.0;
  List<DBRecord> listOfTables = List();
  DBProjectBloc projectBloc;
  TabletInputLine tabletInputLine;

//  FieldMeta inputLineInfo;
//  FieldMeta listViewInfo;
//  FieldMeta projectInfo;
//  FieldMeta tableNameInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Log.t('example initState');
    projectInfo = FieldMeta(
      fieldName: '',
      newNameFunction: (projectName) {
        projectBloc.writeTablesToFile(prettyPrint: true);
        if (tableNameInfo == null) {
          tableNameInfo = FieldMeta(fieldName: '', newNameFunction: (newTableName) {}, debug: 'Table');
        }
        setState(() {
          tableNameInfo.controller.text = '';
        });
      },
      debug: 'Project',
    );
    tabletInputLine = TabletInputLine(fieldInput: fieldInput, sink: inputCompleteStream.sink);
    keyboardVisibilityNotification.addNewListener(onShow: () {
      setState(() {
        listHeight = ScreenSize.height * 0.20;
        Log.f('main.dart show listHeight $listHeight');
      });
    }, onHide: () {
      Log.v('example onHide');
      expand();
    });
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    Log.t('example didChangeDependencies');
    Log.v('example didChangeDependencies => $listHeight');
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
    expand();
    listener();
    Log.f('main.dart removed call to setFocusOn()');
    //setFocusOn(projectInfo.focusNode);
  }

  @override
  Widget build(BuildContext context) {
    Log.t('main.dart build');
    return HudScaffold.progressText(
      context,
      hide: hideSpinner,
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
              hideSpinner = false;
              Future.delayed(Duration(seconds: 3), () {
                setState(() {
                  hideSpinner = true;
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
    inputCompleteStream.dispose();
    keyboardVisibilityNotification.dispose();

    inputLineInfo?.dispose();
    listViewInfo?.dispose();
    projectInfo.dispose();
    tableNameInfo?.dispose();

    super.dispose();
  }

  /// Scaffold body
  Widget body() {
    Log.v('main body() didChangeDependencies => $listHeight');
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: [
            Padding(
              child: WideAnimatedButton(
                playSystemClickSound: true,
                caption: 'Start',
                colors: ModeThemeData.productSwatch,
                height: 60.0,
                onTap: (tap, timestamp) {
                  setFocusOn(projectInfo.focusNode);
                },
                width: 200,
              ),
              padding: const EdgeInsets.all(8.0),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: WideAnimatedButton(
                caption: 'Save',
                colors: ModeThemeData.productSwatch,
                onTap: (tap, timestamp) {
                  if (projectBloc == null) return;
                  projectBloc.writeTablesToFile(prettyPrint: true).then((_) {
                    setState(() {
                      caption = 'Done!!';
                      expand();
                    });
                  });
                },
                height: 60.0,
                width: 200,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: WideAnimatedButton(
                caption: caption,
                colors: ModeThemeData.primarySwatch,
                onLongPress: (event, timeStamp) {},
                height: 60.0,
                width: 200.0,
              ),
            ),
          ],
        ),

        ///Project input field, table name input field
        Row(
          children: <Widget>[
            Container(
              child: NameInputForm(
                  focusNode: projectInfo.focusNode,
                  controller: null,
                  sink: projectInfo.sink,
                  fieldName: projectInfo.name,
                  title: 'Project Name'),
              width: ScreenSize.width * 0.20,
            ),
            Container(
              width: 25,
            ),
            Opacity(
              child: Container(
                  child: NameInputForm(
                      focusNode: tableNameInfo.focusNode,
                      controller: tableNameInfo.controller,
                      sink: tableNameInfo.sink,
                      fieldName: tableNameInfo.name,
                      title: 'Table Name'),
                  width: ScreenSize.width * 0.20),
              opacity: projectInfo.opacity,
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
        ),

        /// Data input line
        Opacity(
          child: tabletInputLine,
          opacity: (projectBloc?.tableCount ?? 0) > 0 ? 1.0 : 0.2,
        ),

        /// Table of data
        Opacity(
          child: Container(
            height: listHeight,
            child: SingleChildScrollView(
              child: (projectInfo.enabled && projectBloc != null)
                  ? DataTable(
                      columns: DBRecord.dataColumns(context),
                      rows: projectBloc.dataRows(
                        context,
                        preferTable: tableNameInfo.name,
                        sink: inputSelectedStream.sink,
                        style: null,
                      ))
                  : Container(),
            ),
          ),
          opacity: projectInfo.opacity,
        ),
      ],
    );
  }

  void makeProject(String name) async {
    if (FieldInput.validateInputField(name: name) != null) return;

    /// Must save any current fields of the project to prevent accidental change of projects without saving.
    if (projectBloc != null) {
      await projectBloc.writeTablesToFile(prettyPrint: true);
    }

    projectBloc = await DBProjectBloc.make(name);
    setState(() {
      projectInfo = FieldMeta(fieldName: name, debug: name);
      tableNameInfo = FieldMeta(fieldName: "", debug: 'Table');
      listOfTables = projectBloc.sortedTableList();
      setFocusOn(tableNameInfo.focusNode);
    });
  }

  void listener() async {
    /// Listener to capture when a new project name was input.
    projectInfo.stream.listen((newProjectName) {
      Log.t('main.dart new project name $newProjectName');
      makeProject(newProjectName);
    });

    /// Listener to capture when a new table was input
    tableNameInfo.stream.listen((newTableName) {
      Log.t('main.dart new tabe name $newTableName');
      setState(() {
        tableNameInfo.dispose();
        tableNameInfo = FieldMeta(name: newTableName, debug: newTableName);
        listOfTables = projectBloc.sortedTableList(newTableName);
        setFocusOn(fieldInput.focusNode(forIndex: FieldInput.indexField));
      });
    });

    /// DBRecord returned by UI when a record is selected
    /// Redraws the input line with that data
    inputSelectedStream.stream.listen((dbRecord) {
      try {
        assert(dbRecord != null);
        fieldInput?.dispose();
        fieldInput = FieldInput.fromDB(record: dbRecord);
        tableNameInfo.controller.text = dbRecord.name;
        setState(() {
          tabletInputLine = TabletInputLine(fieldInput: fieldInput, sink: inputCompleteStream.sink);
        });
      } catch (err) {
        Log.e(err.toString());
      }
    });

    /// Listener when a data line has been completed and ready to add to the list of fields for a table in a project
    /// and reset for another field.
    inputCompleteStream.stream.listen((event) {
      try {
        projectBloc.add(fieldInput: event, toTable: tableNameInfo.name);
        setState(() {
          fieldInput?.dispose();
          fieldInput = FieldInput();
          tabletInputLine = TabletInputLine(fieldInput: fieldInput, sink: inputCompleteStream.sink);
          listOfTables = projectBloc.sortedTableList();
        });
      } catch (err) {
        Log.e(err.toString());
      }
    });
  }

  void expand() {
    setState(() {
      listHeight = ScreenSize.height * 0.70;
      Log.v('main.dart expand $listHeight');
    });
  }

  void setFocusOn(FocusNode node) {
    Future.delayed(Duration(milliseconds: 500), () {
      Log.d('main.dart setFocus on $node');
      FocusScope.of(context).requestFocus(node);
      FocusScope.of(context).requestFocus(node);
    });
  }
}
