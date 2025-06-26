import 'dart:convert';

import 'package:bloknot/image_deck.dart';
import 'package:bloknot/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  String _deletedText = "";
  List<String> _deletedUrls = [];
  bool _visible = true;
  bool _deleteOnVisibilityLossBypass = false; // This is so that when selecting an image, all text is not deleted

  final Color _enabledColor = Colors.white;
  final Color _disabledColor = const Color.fromARGB(255, 187, 187, 187);

  final ImagePicker _picker = ImagePicker();
  List<String> _imageUrls = [];

  Color _speakTextButtonColor = Colors.white;

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
    _checkAvailabilityOfTts();
    WidgetsBinding.instance.addObserver(this);
  }

  void _checkAvailabilityOfTts() async {

    if (await flutterTts.getDefaultEngine == null) {
      
      setState(() {
        _speakTextButtonColor = _disabledColor;
      });

    } else {

      setState(() {
      _speakTextButtonColor = _enabledColor;
    });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((
      state == AppLifecycleState.inactive ||
      state == AppLifecycleState.hidden ||
      state == AppLifecycleState.paused ||
      state == AppLifecycleState.detached) &&
      _visible &&
      !_deleteOnVisibilityLossBypass
    ) {
      _visible = false;
      _clearText();
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

    if (_visible) {
      HapticFeedback.mediumImpact();
    }

    if (_controller.text.isEmpty) {
      return;
    }

    _deletedText = _controller.text;
    _deletedUrls = _imageUrls;

    _controller.clear();
    _imageUrls = [];

    setState((){});
  }

  void _restoreText() {
    HapticFeedback.mediumImpact();
    _controller.text = _deletedText;
    _imageUrls = _deletedUrls;

    setState((){});
  }

  void _speakText() async {
    if (_controller.text.isEmpty) {
      return;
    }


    if (await flutterTts.getDefaultEngine == null) {
      debugPrint("No TTS engine");
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final encodedVoiceString = prefs.getString("voice");

    if (encodedVoiceString != null && encodedVoiceString.isNotEmpty) {

      // Need to do this abomination to convert the string to a map
      Map<String, String> voice =
          (json.decode(encodedVoiceString) as Map<String, dynamic>).map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          );

      await flutterTts.setVoice(voice);
    }
    
    await flutterTts.speak(_controller.text);
  }

  void _pickAndAddPictureFromGallery() async {

    _deleteOnVisibilityLossBypass = true;
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) {
      return;
    } 

    _deleteOnVisibilityLossBypass = false;
    
    _imageUrls.add(image.path);
    setState((){});
    
  }

  void _pickAndAddPictureFromCamera() async {

    _deleteOnVisibilityLossBypass = true;
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    
    if (image == null) {
      return;
    } 

    _deleteOnVisibilityLossBypass = false;
    
    _imageUrls.add(image.path);
    setState((){});
  }

  void _removeImage(String url) {

    setState(() {
      _imageUrls.remove(url);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        left: false,
        right: false,
        bottom: false,
        child: Row(
          children: [
            
            // Column to stack image preview and text
            Expanded(
              child: Column(
                children: [

                  // Text field
                  Expanded(
                    child: Padding( 
                      padding: EdgeInsetsGeometry.fromLTRB(10,0,0,0),
                      child: TextField(
                        expands: true,
                        autofocus: true,
                        focusNode: _focusNode,
                        controller: _controller,
                        maxLines: null,
                        minLines: null,
                        style: TextStyle(fontSize: _fontSize),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  
                  // Image preview section
                  Visibility(
                    visible: _imageUrls.isNotEmpty,
                    child: GestureDetector(
                      
                      child: Container(
                        // color: const Color.fromARGB(255, 209, 209, 209),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: <Color>[
                              Color(0xffaaaaaa),
                              Color(0xffdddddd),
                              Color(0x55ffffff)
                            ]
                          )
                        ),
                        child: ImageDeck(
                          imageUrls: _imageUrls,
                          onRemove: _removeImage,
                        )
                      )
                    ),
                  ),
                ]
              )
            ),
            
            

            // Button Bar on the right
            Container(
              color: Colors.blue,
              child: Column(
                children: [

                  // ======================================= //
                  // TTS Button
                  IconButton(
                    icon: const Icon(Icons.campaign),
                    color: _speakTextButtonColor,
                    tooltip: "Text to Speech",
                    onPressed: () {
                      _speakText();
                    },
                  ),
                  // ======================================= //

                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 60),
                      child: Container(),
                    ),
                  ),

                  // ======================================= //
                  // Increase Font size
                  IconButton(
                    icon: const Icon(Icons.add),
                    color: Colors.white,
                    tooltip: "increase font size",
                    onPressed: () {
                      setState(_incrementFontSize);
                    },
                  ),
                  
                  // Decrease font size
                  IconButton(
                    icon: const Icon(Icons.remove),
                    color: Colors.white,
                    tooltip: "decrease font size",
                    onPressed: () {
                      setState(_decrementFontSize);
                    },
                  ),
                  // ======================================= //

                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 60),
                      child: Container(),
                    ),
                  ),

                  

                  // ======================================= //
                  // Undo
                  IconButton(
                    icon: const Icon(Icons.undo),
                    color: Colors.white,
                    tooltip: "Restores the deleted text",
                    onPressed: _restoreText,
                  ),

                  Container(height: 20),

                  // Delete
                  IconButton(
                    icon: const Icon(Icons.delete_forever),
                    color: Colors.white,
                    tooltip: "clear all text",
                    onPressed: _clearText,
                  ),
                  // ======================================= //


                  Expanded(child: Container()),
                  Expanded(child: Container()),


                  // ======================================= //
                  // Select Image
                  IconButton(
                    icon: const Icon(Icons.add_a_photo),
                    color: Colors.white,
                    onPressed: _pickAndAddPictureFromGallery,
                    onLongPress: _pickAndAddPictureFromCamera,
                  ),

                  // ======================================= //

                  // Instead of just pushing the icon to the bottom,
                  // each one of these just puts it halfway between the bottom and the previous widget,
                  // but by having this many, the original intended effect is achieved
                  // Expanded(child: Container()),
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

                  ConstrainedBox(constraints: BoxConstraints(minHeight: 20))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
