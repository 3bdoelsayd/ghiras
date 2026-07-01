enum StepType { content, quiz, summary }

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    question: json['question'],
    options: List<String>.from(json['options']),
    correctAnswerIndex: json['correctAnswerIndex'],
    explanation: json['explanation'],
  );

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options,
    'correctAnswerIndex': correctAnswerIndex,
    'explanation': explanation,
  };
}

class LessonStep {
  final String id;
  final StepType type;
  final String title;
  final String content;
  final String? imageUrl;
  final List<QuizQuestion>? questions;

  LessonStep({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.imageUrl,
    this.questions,
  });

  factory LessonStep.fromJson(Map<String, dynamic> json) => LessonStep(
    id: json['id'],
    type: StepType.values.firstWhere((e) => e.name == json['type']),
    title: json['title'],
    content: json['content'],
    imageUrl: json['imageUrl'],
    questions: json['questions'] != null
        ? List<QuizQuestion>.from(json['questions'].map((x) => QuizQuestion.fromJson(x)))
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'content': content,
    'imageUrl': imageUrl,
    'questions': questions?.map((x) => x.toJson()).toList(),
  };
}

class IslamicLesson {
  final String id;
  final String title;
  final String category;
  final int order;
  final List<LessonStep> steps;
  bool isCompleted;

  IslamicLesson({
    required this.id,
    required this.title,
    required this.category,
    required this.order,
    required this.steps,
    this.isCompleted = false,
  });

  factory IslamicLesson.fromJson(Map<String, dynamic> json) => IslamicLesson(
    id: json['id'],
    title: json['title'],
    category: json['category'],
    order: json['order'],
    steps: List<LessonStep>.from(json['steps'].map((x) => LessonStep.fromJson(x))),
    isCompleted: json['isCompleted'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'order': order,
    'steps': steps.map((x) => x.toJson()).toList(),
    'isCompleted': isCompleted,
  };
}
