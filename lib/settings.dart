import 'dart:convert';

import 'package:bloknot/color_picker.dart';
import 'package:bloknot/color_picker_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {

  final void Function() toggleNextWordPrediction;
  final bool nextWordPredictionInit;

  final void Function() toggleTopBarOnMainPage;
  final bool topBarOnMainPageInit;

  final void Function(int sRGB) updateTextColor;
  final int textColorInit;

  final void Function(int sRGB) updatePredictedTextColor;
  final int predictedTextColorInit;

  final void Function(int sRGB) updateTextBackgroundColor;
  final int textBackgroundColorInit;

  final void Function(int sRGB) updateAppColor;
  final int appColorInit;

  final void Function(int sRGB) updateAppButtonColor;
  final int appButtonColorInit;

  final void Function(int sRGB) updateDisabledButtonColor;
  final int disabledButtonColorInit;

  final void Function(String fontFamily) updateFontFamily;
  final String fontFamilyInit;

  const SettingsPage({
    super.key,
    required this.toggleNextWordPrediction,
    required this.nextWordPredictionInit,
    required this.toggleTopBarOnMainPage,
    required this.topBarOnMainPageInit, 
    required this.updateTextColor, 
    required this.textColorInit, 
    required this.updatePredictedTextColor, 
    required this.predictedTextColorInit, 
    required this.updateTextBackgroundColor, 
    required this.textBackgroundColorInit, 
    required this.updateAppColor, 
    required this.appColorInit, 
    required this.updateAppButtonColor, 
    required this.appButtonColorInit, 
    required this.updateDisabledButtonColor, 
    required this.disabledButtonColorInit,
    required this.updateFontFamily,
    required this.fontFamilyInit,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FlutterTts flutterTts = FlutterTts();

  String ttsEngineValue = "None";
  List<String> ttsEngineList = <String>[];

  bool _nextWordPrediction = false;
  bool _topBarOnMainPage = false;

  late Color textColor;
  late Color predictedTextColor;
  late Color textBackgroundColor;
  late Color appColor;
  late Color appButtonColor;
  late Color disabledButtonColor;

  late String fontFamily;

  final List<String> fontFamilies = [
    "NotoSans",
    "Roboto",
    "RobotoMono",
    "EBGaramond",
  ];

  String ttsVoiceValue = "None";
  late Map ttsVoice;
  List<String> ttsVoiceList = <String>[];

  void _updateLists() async {


    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString("engine")?.isEmpty ?? true) {
      
      // Use the default values if shared preferences does not exist
      ttsEngineValue = (await flutterTts.getDefaultEngine)?.toString() ?? "";
    } else {
      
      // use the value saved otherwise
      ttsEngineValue = prefs.getString("engine")!.replaceAll(RegExp("^['\"]|['\"]\$"), '');
    }

    ttsEngineList = (await flutterTts.getEngines as List)
      .map((e) => e.toString())
      .toList();

    // Use the default values if shared preferences does not exist
    if (prefs.getString("voice")?.isEmpty ?? true) {
      debugPrint("Using default voice");
      ttsVoiceValue = (await flutterTts.getDefaultVoice)?["name"].toString() ?? "";
    } else {
      
      debugPrint("Loading voice from shared prefs");
      ttsVoiceValue = json.decode(prefs.getString("voice")!)["name"].toString().replaceAll(RegExp("^['\"]|['\"]\$"), '');

      debugPrint(ttsVoiceValue);
    }

    ttsVoiceList = (await flutterTts.getVoices as List)
      .map((e) => e["name"].toString())
      .toList()
      ..sort();

    setState(() {});
  }

  void _updateSavedEngine() async {
    final prefs = await SharedPreferences.getInstance();

    debugPrint("ENGINE ${json.encode(await flutterTts.getDefaultEngine)}");

    prefs.setString("engine", json.encode(ttsEngineValue));
  }

  void _updateSavedVoice() async {
    // get ttsVoice from the ttsVoiceValue filtered from the voice list
    for (dynamic voice in await flutterTts.getVoices) {
      if (voice["name"] == ttsVoiceValue) {
        ttsVoice = voice;
        break;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    prefs.setString("voice", json.encode(ttsVoice));
  }

  @override
  void initState() {
    super.initState();

    _updateLists();

    _nextWordPrediction = widget.nextWordPredictionInit;
    _topBarOnMainPage = widget.topBarOnMainPageInit;

    textColor = Color(widget.textColorInit);
    predictedTextColor = Color(widget.predictedTextColorInit);
    textBackgroundColor = Color(widget.textBackgroundColorInit);
    appColor = Color(widget.appColorInit);
    appButtonColor = Color(widget.appButtonColorInit);
    disabledButtonColor = Color(widget.disabledButtonColorInit);

    fontFamily = widget.fontFamilyInit;

    debugPrint("ENGINE LIST LENGTH ${ttsEngineList.isNotEmpty}");
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            text: "Settings",
            style: TextStyle(color: appButtonColor, fontSize: 25.0),
          ),
        ),
        backgroundColor: appColor,
        iconTheme: IconThemeData(color: appButtonColor),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.all(10),
        child: Table(
          columnWidths: {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(),
          },
          children: [
            TableRow(
              children: [
                Visibility(visible: ttsEngineList.isNotEmpty, child: Text("TTS Engine")),

                Visibility(
                  visible: ttsEngineList.isNotEmpty,
                  child: DropdownButton(
                    value: ttsEngineValue,
                    icon: SizedBox.shrink(),
                    alignment: AlignmentDirectional.topStart,
                    items: ttsEngineList.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),

                    onChanged: (String? value) {
                      setState(() {
                        ttsEngineValue = value!;
                        _updateSavedEngine();
                      });
                    },
                  ),
                ),

              ],
            ),
            
            TableRow(
              children: [
                Visibility(visible: ttsVoiceList.isNotEmpty, child: Text("Voice")),

                Visibility(
                  visible: ttsVoiceList.isNotEmpty, 
                  child: DropdownButton(
                    value: ttsVoiceValue,
                    icon: SizedBox.shrink(),
                    alignment: AlignmentDirectional.topStart,
                    items: ttsVoiceList.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),

                    onChanged: (String? value) {
                      setState(() {
                        ttsVoiceValue = value!;

                        _updateSavedVoice();
                      });
                    },
                  ),
                ),
                
              ]
            ),

            TableRow(
              children: [
                Text("Text Colour"),
                Align(
                  alignment: Alignment.center,
                  child: colorPickerButton(
                    background: textColor, 
                    border: Colors.grey, 
                    onPressed: () async {
                      int? result = await showDialog<int>(
                        context: context,
                        builder: (_) => ColorPickerDialog(initialColor: textColor.toARGB32())
                      );

                      if (result == null) {
                        return;
                      }

                      // update text colour
                      textColor = Color(result);
                      widget.updateTextColor(textColor.toARGB32());
                      setState((){});
                    }, 
                  )      
                )                 
              ]
            ),

            TableRow(
              children: [
                Text("Predicted Text Colour"),
                
                Align(
                  alignment: Alignment.center,
                  child: colorPickerButton(
                    background: predictedTextColor, 
                    border: Colors.grey, 
                    onPressed: () async {
                      int? result = await showDialog<int>(
                        context: context,
                        builder: (_) => ColorPickerDialog(initialColor: predictedTextColor.toARGB32())
                      );

                      if (result == null) {
                        return;
                      }

                      // update text colour
                      predictedTextColor = Color(result);
                      widget.updatePredictedTextColor(predictedTextColor.toARGB32());
                      setState((){});
                    }, 
                  )      
                )
              ]
            ),

            TableRow(
              children: [
                Text("Text Background Colour"),
                Align(
                  alignment: Alignment.center,
                  child: colorPickerButton(
                    background: textBackgroundColor, 
                    border: Colors.grey, 
                    onPressed: () async {
                      int? result = await showDialog<int>(
                        context: context,
                        builder: (_) => ColorPickerDialog(initialColor: textBackgroundColor.toARGB32())
                      );

                      if (result == null) {
                        return;
                      }

                      // update text colour
                      textBackgroundColor = Color(result);
                      widget.updateTextBackgroundColor(textBackgroundColor.toARGB32());
                      setState((){});
                    }, 
                  )      
                )
              ]
            ),

            TableRow(
              children: [
                Text("App Colour"),
                Align(
                  alignment: Alignment.center,
                  child: colorPickerButton(
                    background: appColor, 
                    border: Colors.grey, 
                    onPressed: () async {
                      int? result = await showDialog<int>(
                        context: context,
                        builder: (_) => ColorPickerDialog(initialColor: appColor.toARGB32())
                      );

                      if (result == null) {
                        return;
                      }

                      // update text colour
                      appColor = Color(result);
                      widget.updateAppColor(appColor.toARGB32());
                      setState((){});
                    }, 
                  )      
                )
              ]
            ),

            TableRow(
              children: [
                Text("Button/App Text Colour"),
                Align(
                  alignment: Alignment.center,
                  child: colorPickerButton(
                    background: appButtonColor, 
                    border: Colors.grey, 
                    onPressed: () async {
                      int? result = await showDialog<int>(
                        context: context,
                        builder: (_) => ColorPickerDialog(initialColor: appButtonColor.toARGB32())
                      );

                      if (result == null) {
                        return;
                      }

                      // update text colour
                      appButtonColor = Color(result);
                      widget.updateAppButtonColor(appButtonColor.toARGB32());
                      setState((){});
                    }, 
                  )      
                )
              ]
            ),

            TableRow(
              children: [
                Text("Disabled Button Colour"),
                Align(
                  alignment: Alignment.center,
                  child: colorPickerButton(
                    background: disabledButtonColor, 
                    border: Colors.grey, 
                    onPressed: () async {
                      int? result = await showDialog<int>(
                        context: context,
                        builder: (_) => ColorPickerDialog(initialColor: disabledButtonColor.toARGB32())
                      );

                      if (result == null) {
                        return;
                      }

                      // update text colour
                      disabledButtonColor = Color(result);
                      widget.updateDisabledButtonColor(disabledButtonColor.toARGB32());
                      setState((){});
                    }, 
                  )      
                )
              ]
            ),

            TableRow(
              children: [
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Text("Font Family"),
                ),
                
                Align(
                  alignment: Alignment.center,
                  child: DropdownButton(
                    value: fontFamily,
                    icon: SizedBox.shrink(),
                    alignment: AlignmentDirectional.topStart,
                    items: fontFamilies.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(fontFamily: value)),
                      );
                    }).toList(),

                    onChanged: (String? value) {
                      setState(() {
                        fontFamily = value!;
                        widget.updateFontFamily(value);
                      });
                    },
                  ),
                ),
              ]
            ),

            TableRow(
              children: [
                Text("Top Bar on Main Page"),
                Checkbox(
                  checkColor: appButtonColor,
                  shape: RoundedRectangleBorder(),
                  fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                    if (states.contains(WidgetState.pressed) || states.contains(WidgetState.selected)) {
                      return appColor;
                    }
                    return appButtonColor;
                  }),
                  value: _topBarOnMainPage, 
                  onChanged: (value) {
                    setState(() {
                      _topBarOnMainPage = value ?? true;
                    });
                    widget.toggleTopBarOnMainPage();
                  },
                )
              ]
            ),

            TableRow(
              children: [
                Text("Next Word Prediction"),
                Checkbox(
                  checkColor: appButtonColor,
                  shape: RoundedRectangleBorder(),
                  fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                    if (states.contains(WidgetState.pressed) || states.contains(WidgetState.selected)) {
                      return appColor;
                    }
                    return appButtonColor;
                  }),
                  value: _nextWordPrediction, 
                  onChanged: (value) {
                    setState(() {
                      _nextWordPrediction = value ?? true;
                    });
                    widget.toggleNextWordPrediction();
                  },
                )
              ]
            ),

          ],
        ),
      ),
    );
  }
}
