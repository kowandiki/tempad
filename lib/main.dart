import 'dart:convert';

import 'package:bloknot/image_deck.dart';
import 'package:bloknot/settings.dart';
import 'package:bloknot/word.dart';
import 'package:bloknot/word_prediction.dart';
import 'package:bloknot/workspace_dialog.dart';
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
  bool _visible = true;
  bool _deleteOnVisibilityLossBypass = false; // This is so that when selecting an image, all text is not deleted

  final Color _enabledColor = Colors.white;
  final Color _disabledColor = const Color.fromARGB(255, 187, 187, 187);

  final ImagePicker _picker = ImagePicker();
  List<String> _imageUrls = [];

  Color _speakTextButtonColor = Colors.white;

  double _fontSize = 20;

  Map<String, List<Word>> _weights = {};

  String _predictedWord = "";

  int _currentWorkspace = 0;
  final List<String> _workspaceText = ["", "", "", "", ""];
  final List<String> _workspaceDeletedText = ["", "", "", "", ""];
  final List<List<String>> _workspaceDeletedUrls = [[],[],[],[],[]];

  void _setValues() async {
    final prefs = await SharedPreferences.getInstance();

    double? fontSize = prefs.getDouble("fontSize");

    if (fontSize != null) {
      setState(() {
        _fontSize = fontSize;
      });
    }

    _weights = await readWeightsFromDevice();
  }

  void _saveValues() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setDouble("fontSize", _fontSize);
  }

  final double _minFontSize = 15;
  final double _maxFontSize = 60;
  final double _fontSizeStep = 5;

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _predictedController = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _setValues();
    _checkAvailabilityOfTts();
    WidgetsBinding.instance.addObserver(this);

    _controller.addListener(() {
      _predictNextWord();

      // Only show the word when the selection is at the end
      // just stops the predicted word from always polluting the space
      if (_controller.selection.end == _controller.text.length && _controller.text.isNotEmpty) {
        _predictedController.text = "${_controller.text}$_predictedWord";
      } else {
        _predictedController.text = "";
      }
    });
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
      // This is to avoid writing large amounts of weights constantly
      // so instead only doing it when the app goes into the background
      writeWeightsToDevice(_weights);
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

    if (_controller.text.isEmpty && _imageUrls.isEmpty) {
      return;
    }

    _workspaceDeletedText[_currentWorkspace] = _controller.text;
    _workspaceDeletedUrls[_currentWorkspace] = _imageUrls;

    // update word prediction weights
    updateWeightsFromSentence(_controller.text, _weights);

    _controller.clear();
    _imageUrls = [];

    setState((){});
  }

  void _restoreText() {
    HapticFeedback.mediumImpact();
    _controller.text = _workspaceDeletedText[_currentWorkspace];
    _imageUrls = _workspaceDeletedUrls[_currentWorkspace];

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

  void _goForwardOneChar() {

    if (_controller.selection.end == _controller.text.length) {
      return;
    }

    _controller.selection = TextSelection.collapsed(offset: _controller.selection.end + 1);

  }

  void _predictNextWord() {
    List<String> words = _controller.text.split(" ");
      // String predictedWord = "";
      String prevWord = "";
      String curWord = "";

      // if there is only 1 word, prev word is that word
      // if there is 2 words, but the most recent is empty, prev word is the 1st word
      // if there are 2 or more words, prev word is the word at maxIndex - 1
      // ^ curWord is the word at maxIndex
      int maxIndex = words.length - 1;

      if (maxIndex < 0) {
        prevWord = " ";
        curWord = "";

      } 
      // This means a word is typed but there is no space, so no prevWord still
      else if (maxIndex == 0) {
        prevWord = " ";
        curWord = words[0];

      }
      else {
        prevWord = words[maxIndex - 1];
        curWord = words[maxIndex];
      }

      // get the predicted word
      _predictedWord = getNextWord(prevWord, curWord, _weights);

      // add space to the end of the word if its predicted
      if (_predictedWord.isNotEmpty) {
        _predictedWord = "$_predictedWord ";
      }
      
      // check if predicted word is finishing the current word, if so, 
      // remove the overlapping parts of the predicted word
      if (curWord.length <= _predictedWord.length) {
        _predictedWord = _predictedWord.substring(curWord.length);
      }

  }

  void _goForwardOneWord() {
    // if selection.end is the same as text length and this button is pressed,
    // a predicted word should be inserted (if available)
    if (_controller.selection.end == _controller.text.length) {

      _predictNextWord();
      
      // insert the word and update the selection
      _controller.text = "${_controller.text}$_predictedWord";

      return;
    }

    bool charEncountered = false;
    int index = _controller.selection.end;

    for (; index < _controller.text.length; index++) {

      if (!charEncountered && _controller.text[index] == " ") {
        continue;
      }

      if (_controller.text[index] != " ") {
        charEncountered = true;
        continue;
      }

      break;
    }

    _controller.selection = TextSelection.collapsed(offset: index);
  }

  void _goBackwardOneChar() {

    if (_controller.selection.start == 0) {
      return;
    }

    _controller.selection = TextSelection.collapsed(offset: _controller.selection.start - 1);

  }

  void _goBackwardOneWord() {

    if (_controller.selection.start == 0) {
      return;
    }

    bool charEncountered = false;
    int index = _controller.selection.start - 1;

    for (; index != 0; index--) {

      if (!charEncountered && _controller.text[index] == " ") {
        continue;
      }

      if (_controller.text[index] != " ") {
        charEncountered = true;
        continue;
      }
      index++;
      break;
    }

    _controller.selection = TextSelection.collapsed(offset: index);
  }

  void _changeTextWorkspace() async {
    
    int? result = await showDialog(
      context: context, 
      builder: (BuildContext context) { 
        _workspaceText[_currentWorkspace] = _controller.text;
        return WorkspaceDialog(
          clearWorkspaceText: _clearWorkspace, 
          activeWorkspaces: _workspaceText.map((e) => e.isNotEmpty).toList(),
        ); 
      }
    );

    if (result == null) {
      return;
    }

    setState((){
      _workspaceText[_currentWorkspace] = _controller.text;

      _currentWorkspace = result;

      _controller.text = _workspaceText[_currentWorkspace];
    });
    
  }

  void _clearWorkspace(int workspaceID) {

    if (workspaceID == _currentWorkspace) {
  
      _workspaceDeletedText[workspaceID] = _controller.text;
      _workspaceText[workspaceID] = "";
      _controller.text = "";
      setState((){});
      HapticFeedback.mediumImpact();

    } else {
  
      _workspaceDeletedText[workspaceID] = _workspaceText[workspaceID];
      _workspaceText[workspaceID] = "";
  
    }

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
                    child: Stack(
                      children: [
                        Padding( 
                          padding: EdgeInsetsGeometry.fromLTRB(10,0,0,0),
                          child: TextField(
                            expands: true,
                            autofocus: false,
                            // focusNode: _focusNode,
                            controller: _predictedController,
                            maxLines: null,
                            minLines: null,
                            style: TextStyle(fontSize: _fontSize, color: Colors.grey),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                            ),
                          ),
                        ),

                        Padding( 
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
                      ]
                    )
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

                  // Button Bar on the bottom
                  Container(
                    color: Colors.blue,
                    child: Row(
                      children: [
                        
                        Padding(padding: EdgeInsets.only(left: 20),),

                        // ======================================= //
                        // change text position back 1 word
                        IconButton(
                          icon: const Icon(Icons.keyboard_double_arrow_left),
                          color: Colors.white,
                          tooltip: "Go back 1 word",
                          onPressed: () {
                            _goBackwardOneWord();
                          },
                        ),
                        // ======================================= //

                        // ======================================= //
                        // change text position back 1 character
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_left),
                          color: Colors.white,
                          tooltip: "Go back 1 character",
                          onPressed: () {
                            _goBackwardOneChar();
                          },
                        ),
                        // ======================================= //

                        Expanded(child: Container()),

                        // ======================================= //
                        // workspaces / prepared phrases pages
                        ElevatedButton(
                          onPressed: _changeTextWorkspace, 
                          child: Text("workspace $_currentWorkspace")
                        ),
                        // ======================================= //

                        Expanded(child: Container()),

                        // ======================================= //
                        // change text position forward 1 character
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_right),
                          color: Colors.white,
                          tooltip: "Go forward 1 character",
                          onPressed: () {
                            _goForwardOneChar();
                          },
                        ),
                        // ======================================= //

                        // ======================================= //
                        // change text position forward 1 word
                        IconButton(
                          icon: const Icon(Icons.keyboard_double_arrow_right),
                          color: Colors.white,
                          tooltip: "Go back 1 word",
                          onPressed: () {
                            _goForwardOneWord();
                          },
                        ),
                        // ======================================= //

                        Padding(padding: EdgeInsets.only(right: 20),),

                      ]
                    )
                  ),
                ]
              )
            ),
            
            

            // Button Bar on the right
            Container(
              color: Colors.blue,
              child: Column(
                children: [

                  Expanded(child: Container()),

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

                  Expanded(child: Container()),

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

                  Expanded(child: Container()),
                  
                  // ======================================= //
                  // Settings
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
                  // ======================================= //

                  Expanded(child: Container()),

                  // ======================================= //
                  // Undo
                  IconButton(
                    icon: const Icon(Icons.undo),
                    color: Colors.white,
                    tooltip: "Restores the deleted text",
                    onPressed: _restoreText,
                  ),


                  // Delete
                  IconButton(
                    icon: const Icon(Icons.delete_forever),
                    color: Colors.white,
                    tooltip: "clear all text",
                    onPressed: _clearText,
                  ),
                  // ======================================= //

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
