import 'dart:convert';

import 'package:bloknot/globals.dart';
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

  final List<String> fontFamily = const ["EBGaramond"];

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: "NotoSans",
      ),
      home: const MyHomePage(title: 'Tempad'),
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

  bool _doNextWordPrediction = true;
  bool _doNextWordPredictionTraining = true;
  bool _showTopBar = false;

  bool _useCustomButtonPlacements = false;
  bool _setCustomButtonPlacements = false;

  double _ttsButtonOffset               = 0.0;
  double _increaseFontSizeButtonOffset  = 25.0;
  double _decreaseFontSizeButtonOffset  = 50.0;
  double _cameraButtonOffset            = 75.0;
  double _settingsButtonOffset          = 100.0;
  double _undoButtonOffset              = 125.0;
  double _deleteButtonOffset            = 150.0;

  final ImagePicker _picker = ImagePicker();
  List<String> _imageUrls = [];

  String _fontFamily = "NotoSans";

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

    _doNextWordPrediction = prefs.getBool("doNextWordPrediction") ?? true;

    _showTopBar = prefs.getBool("showTopBar") ?? false;

    Globals.textColor = Color(prefs.getInt("textColor") ?? Globals.textColor.toARGB32());
    Globals.predictedTextColor = Color(prefs.getInt("predictedTextColor") ?? Globals.predictedTextColor.toARGB32());
    Globals.textBackgroundColor = Color(prefs.getInt("textBackgroundColor") ?? Globals.textBackgroundColor.toARGB32());
    Globals.appColor = Color(prefs.getInt("appColor") ?? Globals.appColor.toARGB32());
    Globals.appButtonColor = Color(prefs.getInt("appButtonColor") ?? Globals.appButtonColor.toARGB32());
    Globals.disabledButtonColor = Color(prefs.getInt("disabledButtonColor") ?? Globals.disabledButtonColor.toARGB32());

    _fontFamily = prefs.getString("fontFamily") ?? "NotoSans";

    _weights = await readWeightsFromDevice();

    _useCustomButtonPlacements = prefs.getBool("useCustomButtonLocations") ?? false;

    _ttsButtonOffset = prefs.getDouble("ttsButtonOffset") ?? 0.0;
    _increaseFontSizeButtonOffset = prefs.getDouble("increaseFontSizeButtonOffset") ?? 25.0;
    _decreaseFontSizeButtonOffset = prefs.getDouble("decreaseFontSizeButtonOffset") ?? 50.0;
    _cameraButtonOffset = prefs.getDouble("cameraButtonOffset") ?? 75.0;
    _settingsButtonOffset = prefs.getDouble("settingsButtonOffset") ?? 100.0;
    _undoButtonOffset = prefs.getDouble("undoButtonOffset") ?? 125.0;
    _deleteButtonOffset = prefs.getDouble("deleteButtonOffset") ?? 150.0;
  }

  void _saveValues() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setDouble("fontSize", _fontSize);
  }

  final double _minFontSize = 15;
  final double _maxFontSize = 60;
  final double _fontSizeStep = 5;

  bool ttsEnabled = false;

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

  void _updateFontFamily(String fontFamily) async {

    _fontFamily = fontFamily;
    setState((){});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("fontFamily", _fontFamily);
  }

  void _toggleNextWordPrediction() async {
   
    _doNextWordPrediction = !_doNextWordPrediction;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("doNextWordPrediction", _doNextWordPrediction);

  }

  void _toggleNextWordPredictionTraining() async {

    _doNextWordPredictionTraining = !_doNextWordPredictionTraining;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("doNextWordPredictionTraining", _doNextWordPredictionTraining);
  }

  void _toggleTopBar() async {

    _showTopBar = !_showTopBar;
    setState((){});

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("showTopBar", _showTopBar);

  }

  void _updateTextColor(int sRGB) async {

    setState(() {
     Globals.textColor = Color(sRGB);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("textColor", Globals.textColor.toARGB32());
  }

  void _updatePredictedTextColor(int sRGB) async {

    setState(() {
      Globals.predictedTextColor = Color(sRGB);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("predictedTextColor", Globals.predictedTextColor.toARGB32());
  }

  void _updateTextBackgroundColor(int sRGB) async {

    setState(() {
      Globals.textBackgroundColor = Color(sRGB);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("textBackgroundColor", Globals.textBackgroundColor.toARGB32());
  }

  void _updateAppColor(int sRGB) async {

    setState(() {
      Globals.appColor = Color(sRGB);
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("appColor", Globals.appColor.toARGB32());
    
  }

  void _updateAppButtonColor(int sRGB) async {

    setState(() {
      Globals.appButtonColor = Color(sRGB);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("appButtonColor", Globals.appButtonColor.toARGB32());
  }

  void _updateDisabledButtonColor(int sRGB) async {

    setState(() {
      Globals.disabledButtonColor = Color(sRGB);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("disabledButtonColor", Globals.disabledButtonColor.toARGB32());

    
  }

  void _checkAvailabilityOfTts() async {

    if (await flutterTts.getDefaultEngine == null) {
      
      setState(() {
        ttsEnabled = false;
      });

    } else {

      setState(() {
        ttsEnabled = true;
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
    setState((){});
  }

  void _incrementFontSize() {
    HapticFeedback.mediumImpact();

    _fontSize += _fontSizeStep;

    if (_fontSize > _maxFontSize) {
      _fontSize = _maxFontSize;
    }

    _saveValues();
    setState((){});
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
    if (_doNextWordPredictionTraining) {
      updateWeightsFromSentence(_controller.text, _weights);
    }

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

    // do nothing if we aren't predicting the next word
    if (!_doNextWordPrediction) {
      return;
    }

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

  void resetCustomButtonOffsets() {
    _ttsButtonOffset = 0.0;
    _increaseFontSizeButtonOffset = 25.0;
    _decreaseFontSizeButtonOffset = 50.0;
    _cameraButtonOffset = 75.0;
    _settingsButtonOffset = 100.0;
    _undoButtonOffset = 125.0;
    _deleteButtonOffset = 150.0;
    setState((){});
    _saveCustomButtonOffsets();
  }

  void _setSettingCustomButtonPlacements(bool value) {
    _setCustomButtonPlacements = value;
    
    _saveCustomButtonOffsets();
  }

  void _toggleUsingCustomButtonPlacements() async {
    _useCustomButtonPlacements = !_useCustomButtonPlacements;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("useCustomButtonLocations", _useCustomButtonPlacements);

    setState((){});
  }

  void _saveCustomButtonOffsets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("ttsButtonOffset", _ttsButtonOffset);
    await prefs.setDouble("increaseFontSizeButtonOffset", _increaseFontSizeButtonOffset);
    await prefs.setDouble("decreaseFontSizeButtonOffset", _decreaseFontSizeButtonOffset);
    await prefs.setDouble("cameraButtonOffset", _cameraButtonOffset);
    await prefs.setDouble("settingsButtonOffset", _settingsButtonOffset);
    await prefs.setDouble("undoButtonOffset", _undoButtonOffset);
    await prefs.setDouble("deleteButtonOffset", _deleteButtonOffset);
  }

  @override
  Widget build(BuildContext context) {

    double padding = 12.0;

    Widget ttsButton = GestureDetector(
      onTap: _speakText,
      onVerticalDragUpdate: (dragUpdateDetails) {
        if (_setCustomButtonPlacements) {
          if (dragUpdateDetails.localPosition.dy > 0 && dragUpdateDetails.localPosition.dy < MediaQuery.sizeOf(context).height) {
            _ttsButtonOffset = dragUpdateDetails.localPosition.dy;
          }
          setState((){});
        }
      },
      child: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(padding, (_ttsButtonOffset*(_useCustomButtonPlacements ? 1 : 0))+padding, padding, padding),
        child: Icon(
          Icons.campaign,
          color: Globals.appButtonColor,
        ),
      )
    );
    
    Widget increaseFontSizeButton = GestureDetector(
      onTap: _incrementFontSize,
      onVerticalDragUpdate: (dragUpdateDetails) {
        if (_setCustomButtonPlacements) {
          if (dragUpdateDetails.localPosition.dy > 0 && dragUpdateDetails.localPosition.dy < MediaQuery.sizeOf(context).height) {
            _increaseFontSizeButtonOffset = dragUpdateDetails.localPosition.dy;
          }
          setState((){});
        }
      },
      child: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(padding, (_increaseFontSizeButtonOffset*(_useCustomButtonPlacements ? 1 : 0))+padding, padding, padding),
        child: Icon(
          Icons.add,
          color: Globals.appButtonColor
        ),
      ),
    );

    Widget decreaseFontSizeButton = GestureDetector(
      onTap: _decrementFontSize,
      onVerticalDragUpdate: (dragUpdateDetails) {
        if (_setCustomButtonPlacements) {
          if (dragUpdateDetails.localPosition.dy > 0 && dragUpdateDetails.localPosition.dy < MediaQuery.sizeOf(context).height) {
            _decreaseFontSizeButtonOffset = dragUpdateDetails.localPosition.dy;
          }
          
          setState((){});
        }
      },
      child: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(padding, (_decreaseFontSizeButtonOffset*(_useCustomButtonPlacements ? 1 : 0))+padding, padding, padding),
        child: Icon(
          Icons.remove,
          color: Globals.appButtonColor
        ),
      )
    );

    Widget selectImageButton = GestureDetector(
      onTap: _pickAndAddPictureFromGallery,
      onLongPress: _pickAndAddPictureFromCamera,
      onVerticalDragUpdate: (dragUpdateDetails) {
        if (_setCustomButtonPlacements) {
          if (dragUpdateDetails.localPosition.dy > 0 && dragUpdateDetails.localPosition.dy < MediaQuery.sizeOf(context).height) {
            _cameraButtonOffset = dragUpdateDetails.localPosition.dy;
          }
          setState((){});
        }
      },
      child: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(padding, (_cameraButtonOffset*(_useCustomButtonPlacements ? 1 : 0))+padding, padding, padding),
        child: Icon(
          Icons.add_a_photo,
          color: Globals.appButtonColor
        ),
      )
    );

    Widget settingsButton = GestureDetector(
      onTap: () async {
        // await so that we can call setState after the return in case the user is setting custom button placements
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsPage(
              toggleNextWordPrediction: _toggleNextWordPrediction,
              nextWordPredictionInit: _doNextWordPrediction,
              toggleNextWordPredictionTraining: _toggleNextWordPredictionTraining,
              nextWordPredictionTrainingInit: _doNextWordPredictionTraining,
              toggleTopBarOnMainPage: _toggleTopBar,
              topBarOnMainPageInit: _showTopBar,
              updateTextColor: _updateTextColor,
              updatePredictedTextColor: _updatePredictedTextColor,
              updateTextBackgroundColor: _updateTextBackgroundColor,
              updateAppColor: _updateAppColor,
              updateAppButtonColor: _updateAppButtonColor,
              updateDisabledButtonColor: _updateDisabledButtonColor,
              updateFontFamily: _updateFontFamily,
              fontFamilyInit: _fontFamily,
              resetCustomButtonOffsets: resetCustomButtonOffsets,
              setSettingCustomButtonPlacements: _setSettingCustomButtonPlacements,
              toggleUsingCustomButtonPlacements: _toggleUsingCustomButtonPlacements,
              useCustomButtonPlacementsInit: _useCustomButtonPlacements,
            ),
          ),
        );
        setState((){});
      },
      onVerticalDragUpdate: (dragUpdateDetails) {
        if (_setCustomButtonPlacements) {
          if (dragUpdateDetails.localPosition.dy > 0 && dragUpdateDetails.localPosition.dy < MediaQuery.sizeOf(context).height * 0.7) {
            _settingsButtonOffset = dragUpdateDetails.localPosition.dy;
          }
          setState((){});
        }
      },
      child: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(padding, (_settingsButtonOffset*(_useCustomButtonPlacements ? 1 : 0))+padding, padding, padding),
        child: Icon(
          Icons.settings,
          color: Globals.appButtonColor
        ),
      ),
    );

    Widget undoButton = GestureDetector(
      onTap: _restoreText,
      onVerticalDragUpdate: (dragUpdateDetails) {
        if (_setCustomButtonPlacements) {
          if (dragUpdateDetails.localPosition.dy > 0 && dragUpdateDetails.localPosition.dy < MediaQuery.sizeOf(context).height) {
            _undoButtonOffset = dragUpdateDetails.localPosition.dy;
          }
          setState((){});
        }
      },
      child: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(padding, (_undoButtonOffset*(_useCustomButtonPlacements ? 1 : 0))+padding, padding, padding),
        child: Icon(
          Icons.undo,
          color: Globals.appButtonColor
        ),
      ),
    );

    Widget deleteButton = GestureDetector(
      onTap: _clearText,
      onVerticalDragUpdate: (dragUpdateDetails) {
        if (_setCustomButtonPlacements) {
          if (dragUpdateDetails.localPosition.dy > 0 && dragUpdateDetails.localPosition.dy < MediaQuery.sizeOf(context).height) {
            _deleteButtonOffset = dragUpdateDetails.localPosition.dy;
          }
          setState((){});
        }
      },
      child: Padding(padding: EdgeInsetsGeometry.fromLTRB(padding, (_deleteButtonOffset*(_useCustomButtonPlacements ? 1 : 0))+padding, padding, padding),
      child: Icon(
          Icons.delete_forever,
          color: Globals.appButtonColor
        ),
      ),
    );


    return Scaffold(
      backgroundColor: Globals.textBackgroundColor,
      appBar: (_showTopBar ? 
        PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: AppBar(
            backgroundColor: Globals.appColor,
            elevation: 0
          ) 
        ) 
        : null // No AppBar if _showTopBar is false
      ),
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
                            style: TextStyle(fontSize: _fontSize, color: Globals.predictedTextColor, fontFamily: _fontFamily),
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
                            style: TextStyle(fontSize: _fontSize, color: Globals.textColor, fontFamily: _fontFamily),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                            ),
                          ),
                        ),

                        Visibility(
                          visible: _setCustomButtonPlacements,
                          child: Padding(
                            padding: EdgeInsetsGeometry.all(30),
                            child: Stack(
                              children: [
                                Container(
                                  color: Globals.appColor,
                                ),
                                Padding(
                                  padding: EdgeInsetsGeometry.all(5),
                                  child: RichText(
                                    text: TextSpan(
                                      text: "Hold and drag the icons on the side to move them up or down into your preferred layout. Once you're happy with the layout, just click on the settings button again. \n\nNote: Make sure the settings button always remains accessible",
                                      style: TextStyle(color: Globals.appButtonColor, fontSize: 20.0),
                                    ),
                                  ),
                                )
                                
                              ]
                            )
                          )
                        )

                      ]
                    )
                  ),
                  
                  // Image preview section
                  Visibility(
                    visible: _imageUrls.isNotEmpty,
                    child: GestureDetector(
                      
                      child: Container(
                        // color: const Color.fromARGB(255, 209, 209, 209),
                        decoration: BoxDecoration(
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
                    color: Globals.appColor,
                    child: Row(
                      children: [
                        
                        Padding(padding: EdgeInsets.only(left: 20),),

                        // ======================================= //
                        // change text position back 1 word
                        IconButton(
                          icon: const Icon(Icons.keyboard_double_arrow_left),
                          color: Globals.appButtonColor,
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
                          color: Globals.appButtonColor,
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
                          child: Text("ws $_currentWorkspace")
                        ),
                        // ======================================= //

                        Expanded(child: Container()),

                        // ======================================= //
                        // change text position forward 1 character
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_right),
                          color: Globals.appButtonColor,
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
                          color: Globals.appButtonColor,
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
            Visibility(
              visible: !_useCustomButtonPlacements,
              child: Container(
                color: Globals.appColor,
                child: Column(
                  children: [

                    Expanded(child: Container()),

                    ttsButton,

                    Expanded(child: Container()),

                    increaseFontSizeButton,
                    decreaseFontSizeButton,

                    Expanded(child: Container()),

                    selectImageButton,

                    Expanded(child: Container()),
                    
                    settingsButton,

                    Expanded(child: Container()),

                    undoButton,
                    deleteButton,

                  ],
                ),
              ),
            ),
            

            // Alternative button bar that uses custom user placements
            Visibility(
              visible: _useCustomButtonPlacements,
              child: Container(
                color: Globals.appColor, 
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ttsButton,
                        increaseFontSizeButton,
                        decreaseFontSizeButton,
                        selectImageButton,
                        undoButton,
                        deleteButton,
                        settingsButton, // have last so its always accessible
                      ]
                    ),
                  ]
                )
              )
            ),
          ],
        ),
      ),
    );
  }
}
