
class Word implements Comparable<Word> {
  final String word;
  final int frequency;

  Word(this.word, this.frequency);

  @override
  int compareTo(Word other) {
    return frequency.compareTo(other.frequency);
  }

  @override
  String toString() {
    return "($word=$frequency)";
  }

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      json["word"] as String,
      json["frequency"] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    "word": word,
    "frequency": frequency,
  };
}