
/*
This file should contain helper functions for updating frequencies, and looking up candidate words using bigrams

weights should be stored in a map where the value of the map is a sorted array with highest frequency words first
the array should consist of Word tuples, as defined in word.dart
the words inside the first word should be the frequency of that word showing up after the base word

Example:
{
word1: {
    2ndwordfreq1: 3
    2ndwordfreq2: 1
    2ndwordfreq3: 1
  }
word2: {
    ...
  }
...
}
*/
import 'dart:convert';

import 'package:bloknot/word.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// returns index of the word in wordList, -1 if not found
int indexOfWord(List<Word> wordList, word) {

  for (int index = 0; index < wordList.length; index++) {

    if (wordList[index].word == word) {
      return index;
    }
  }

  return -1;

}

/// Function takes a series of words "sentence" and weights and update the weights for each word that occurs in the sentence
/// Returns the updated weights
Future<Map<String, List<Word>>> updateWeightsFromSentence(String sentence, Map<String, List<Word>> weights) async {
  
  // split the sentence by spaces. Keep punctuation and capitalization
  List<String> words = sentence.split(" ");

  // keep track of the previous word
  // use a space to designate the word that starts a sentence
  String prevWord = " ";

  // go through each word in the word list and update the weights
  for (String word in words) {

    // skip if the split gave an empty string
    if (word.isEmpty) {
      continue;
    }

    // find the previous word to update the weight of the current word
    if (weights.containsKey(prevWord)) {
      // find word in the list of words
      int index = indexOfWord(weights[prevWord]!, word);

      if (index >= 0) {
        // update weight
        weights[prevWord]![index] = Word(word, weights[prevWord]![index].frequency + 1);

        // sort list (in reverse)
        weights[prevWord]!.sort((a,b) => b.compareTo(a));

      } else {
        // if it does not exist, add it to the end and set its frequency to 1
        weights[prevWord]!.add(Word(word, 1));
      }
    } else {
      // prevWord is not in weights so add it
      weights[prevWord] = [];
      // no more work to do here
    }

    // update the previous word for the next iteration
    prevWord = word;
  }

  return weights;
}

/// Gets the predicted next word based on the previous word
/// Filters based off of any words that partially match the current word supplied
/// returns an empty string if there is no predicted word
String getNextWord(String prevWord, String currentWord, Map<String, List<Word>> weights) {

  // if there is no known use of prevWord, can't predict next so return empty string
  if (!weights.containsKey(prevWord)) {
    return "";
  }

  // grab the list of words for prevWord
  // find the first string in the list of words that matches currentWord
  for (Word word in weights[prevWord]!) {

    // this words for empty strings too in case the next word hasn't been written yet
    if (word.word.startsWith(currentWord)) {
      return word.word;
    }

  }

  return "";
}


/// Writes the weights passed in to persistent storage
void writeWeightsToDevice(Map<String, List<Word>> weights) async {

  final prefs = await SharedPreferences.getInstance();

  await prefs.setString("weights", json.encode(weights));
  
}

/// Reads weights stored in persistent storage and returns them
Future<Map<String, List<Word>>> readWeightsFromDevice() async {
  
  final prefs = await SharedPreferences.getInstance();

  Map<String, dynamic> decoded = json.decode(prefs.getString("weights")!);

  Map<String, List<Word>> weights = decoded.map((key, value) {
    return MapEntry(
      key,
      (value as List)
        .map((e) => Word.fromJson(e as Map<String, dynamic>))
        .toList(),
    );
  });

  return weights;
}