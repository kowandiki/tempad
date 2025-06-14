import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FlutterTts flutterTts = FlutterTts();

  String ttsEngineValue = "None";
  late Map ttsEngine;
  List<String> ttsEngineList = <String>[];

  String ttsVoiceValue = "None";
  late Map ttsVoice;
  List<String> ttsVoiceList = <String>[];

  void _updateLists() async {
    ttsEngineList = (await flutterTts.getEngines as List)
        .map((e) => e.toString())
        .toList();

    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString("engine")?.isEmpty ?? true) {
      
      // Use the default values if shared preferences does not exist
      ttsEngineValue = (await flutterTts.getDefaultEngine)?.toString() ?? '';
    } else {
      
      // use the value saved otherwise
      ttsEngineValue = prefs.getString("engine")!;
    }


    if (prefs.getString("voice")?.isEmpty ?? true) {
      
      ttsVoiceValue = (await flutterTts.getDefaultVoice)?.toString() ?? "";
    } else {

      // ttsVoiceValue = 
    }

    ttsVoiceList = (await flutterTts.getVoices as List)
        .where(
          (e) =>
            (
              // This filtering only works with googles TTS engine
              // Alternatives to this should be looked into
              e["name"].toString().endsWith("language") &&
              e["quality"] == "high" &&
              e["network_required"] == "0" &&
              e["latency"] == "low"
            ),
        )
        .map((e) => e["name"].toString())
        .toList();

    // Use the default values if shared preferences does not exist
    ttsVoice = await flutterTts.getDefaultVoice;
    ttsVoiceValue = ttsVoice["name"] == null ? "None" : ttsVoice["name"]!;

    setState(() {});
  }

  void _updateSavedEngine() async {
    final prefs = await SharedPreferences.getInstance();

    debugPrint("ENGINE ${json.encode(await flutterTts.getDefaultEngine)}");

    prefs.setString("engine", json.encode(ttsEngine));
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            text: "Settings",
            style: TextStyle(color: Colors.white, fontSize: 25.0),
          ),
        ),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.all(10),
        child: Column(
          children: [
            DropdownButton(
              value: ttsEngineValue,
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

            DropdownButton(
              value: ttsVoiceValue,
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
          ],
        ),
      ),
    );
  }
}
