import 'package:bloknot/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  String _deletedText = "";
  bool _visible = true;

  double _fontSize = 20;

  void _setValues() async {
    final prefs = await SharedPreferences.getInstance();

    double? fontSize = prefs.getDouble("fontSize");

    if (fontSize != null) {
      setState(() {
        _fontSize = fontSize;
      });
    }
  }

  void _saveValues() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setDouble("fontSize", _fontSize);
  }

  final double _minFontSize = 15;
  final double _maxFontSize = 60;
  final double _fontSizeStep = 5;

  final TextEditingController _controller = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _setValues();
    flutterTts.setEngine(flutterTts.getDefaultEngine.toString());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached) &&
        _visible) {
      _visible = false;
      setState(() {
        if (_controller.text.isNotEmpty) {
          _deletedText = _controller.text;
          _controller.text = "";
        }
      });
    } else {
      _visible = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _decrementFontSize() {
    HapticFeedback.mediumImpact();

    _fontSize -= _fontSizeStep;

    if (_fontSize < _minFontSize) {
      _fontSize = _minFontSize;
    }

    _saveValues();
  }

  void _incrementFontSize() {
    HapticFeedback.mediumImpact();

    _fontSize += _fontSizeStep;

    if (_fontSize > _maxFontSize) {
      _fontSize = _maxFontSize;
    }

    _saveValues();
  }

  void _clearText() {
    HapticFeedback.mediumImpact();

    if (_controller.text.isEmpty) {
      return;
    }

    _deletedText = _controller.text;

    _controller.clear();
  }

  void _restoreText() {
    HapticFeedback.mediumImpact();
    _controller.text = _deletedText;
  }

  void _speakText() async {
    if (_controller.text.isEmpty) {
      return;
    }


    // final prefs = await SharedPreferences.getInstance();

    // final encodedVoiceString = prefs.getString("voice");

    // if (encodedVoiceString != null && encodedVoiceString.isNotEmpty) {

    //   debugPrint(encodedVoiceString);
    //   // Need to do this abomination to convert the string to a map
    //   Map<String, String> voice =
    //       (json.decode(encodedVoiceString) as Map<String, dynamic>).map(
    //         (key, value) => MapEntry(key.toString(), value.toString()),
    //       );

    //   await flutterTts.setVoice(voice);
    // }

    await flutterTts.speak(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Container(
          //   height: MediaQuery.of(context).padding.top,
          //   color: Colors.blue,
          // ),
          SafeArea(
            left: false,
            right: false,
            bottom: false,
            child: Padding(
              padding: EdgeInsetsGeometry.fromLTRB(10, 0, 0, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      expands: true,
                      autofocus: true,
                      focusNode: _focusNode,
                      controller: _controller,
                      maxLines: null,
                      minLines: null,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  ),

                  Container(
                    // height: double.infinity,
                    color: Colors.blue,
                    child: Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_forever),
                          color: Colors.white,
                          tooltip: "clear all text",
                          onPressed: _clearText,
                        ),

                        Container(height: 0),

                        IconButton(
                          icon: const Icon(Icons.undo),
                          color: Colors.white,
                          tooltip: "Restores the deleted text",
                          onPressed: _restoreText,
                        ),

                        Flexible(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 60),
                            child: Container(),
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.add),
                          color: Colors.white,
                          tooltip: "increase font size",
                          onPressed: () {
                            setState(_incrementFontSize);
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.remove),
                          color: Colors.white,
                          tooltip: "decrease font size",
                          onPressed: () {
                            setState(_decrementFontSize);
                          },
                        ),

                        Flexible(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 60),
                            child: Container(),
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.campaign),
                          color: Colors.white,
                          tooltip: "Text to Speech",
                          onPressed: () {
                            _speakText();
                          },
                        ),

                        // Flexible(
                        //   child: ConstrainedBox(
                        //     constraints: BoxConstraints(maxHeight: 10),
                        //     child: Container()
                        //   )
                        // ),

                        // Instead of just pushing the icon to the bottom,
                        // each one of these just puts it halfway between the bottom and the previous widget,
                        // but by having this many, the original intended effect is achieved
                        Expanded(child: Container()),
                        Expanded(child: Container()),
                        Expanded(child: Container()),
                        Expanded(child: Container()),
                        Expanded(child: Container()),
                        Expanded(child: Container()),
                        Expanded(child: Container()),
                        Expanded(child: Container()),

                        IconButton(
                          icon: const Icon(Icons.settings),
                          color: Colors.white,
                          tooltip: "Settings",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
