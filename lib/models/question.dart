enum QuestionType { choice, slider }

class Question {
  final String id;
  final String text;
  final String? imageUrl;
  final QuestionType type;

  // For Choice
  final List<String> options;
  final int correctOptionIndex;

  // For Slider
  final double minSlider;
  final double maxSlider;
  final double correctNumber;

  Question({
    required this.id,
    required this.text,
    this.imageUrl,
    this.type = QuestionType.choice,
    this.options = const [],
    this.correctOptionIndex = -1,
    this.minSlider = 0,
    this.maxSlider = 100,
    this.correctNumber = 0,
  });
}
