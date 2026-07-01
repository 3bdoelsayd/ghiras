import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/islamic_lesson_model.dart';

class LessonController extends GetxController {
  var lessons = <IslamicLesson>[].obs;
  var isLoading = true.obs;
  var completedLessonIds = <String>{}.obs;
  
  // Progress for the current lesson session
  var currentStepIndex = 0.obs;
  var score = 0.obs;
  var quizAnswered = false.obs;
  var selectedOptionIndex = (-1).obs;
  var isCorrect = false.obs;

  final Box _box = Hive.box('settings');

  @override
  void onInit() {
    super.onInit();
    loadLessons();
    loadProgress();
  }

  Future<void> loadLessons() async {
    try {
      isLoading(true);
      final String response = await rootBundle.loadString('assets/data/islamic_lessons.json');
      final data = await json.decode(response);
      
      // Handle both formats: Direct list or nested under 'lessons' key
      List listData;
      if (data is Map && data.containsKey('lessons')) {
        listData = data['lessons'];
      } else {
        listData = data as List;
      }

      lessons.value = listData.map((json) => IslamicLesson.fromJson(json)).toList();
      lessons.sort((a, b) => a.order.compareTo(b.order));
      _updateLessonsCompletionStatus();
    } catch (e) {
      print("Error loading lessons: $e");
    } finally {
      isLoading(false);
    }
  }

  void loadProgress() {
    final List<dynamic>? completed = _box.get('completed_islamic_lessons');
    if (completed != null) {
      completedLessonIds.value = completed.cast<String>().toSet();
    }
    _updateLessonsCompletionStatus();
  }

  void _updateLessonsCompletionStatus() {
    for (var lesson in lessons) {
      lesson.isCompleted = completedLessonIds.contains(lesson.id);
    }
    lessons.refresh();
  }

  Future<void> markLessonComplete(String lessonId) async {
    completedLessonIds.add(lessonId);
    await _box.put('completed_islamic_lessons', completedLessonIds.toList());
    _updateLessonsCompletionStatus();
  }

  void startLesson(IslamicLesson lesson) {
    currentStepIndex.value = 0;
    score.value = 0;
    resetQuizState();
  }

  void nextStep(IslamicLesson lesson) {
    if (currentStepIndex.value < lesson.steps.length - 1) {
      currentStepIndex.value++;
      resetQuizState();
    } else {
      markLessonComplete(lesson.id);
    }
  }

  void previousStep() {
    if (currentStepIndex.value > 0) {
      currentStepIndex.value--;
      resetQuizState();
    }
  }

  void resetQuizState() {
    quizAnswered.value = false;
    selectedOptionIndex.value = -1;
    isCorrect.value = false;
  }

  void submitAnswer(QuizQuestion question, int index) {
    if (quizAnswered.value) return;
    
    selectedOptionIndex.value = index;
    quizAnswered.value = true;
    isCorrect.value = (index == question.correctAnswerIndex);
    
    if (isCorrect.value) {
      score.value++;
    }
  }

  double getLessonProgress(String lessonId) {
    return completedLessonIds.contains(lessonId) ? 1.0 : 0.0;
  }
}
