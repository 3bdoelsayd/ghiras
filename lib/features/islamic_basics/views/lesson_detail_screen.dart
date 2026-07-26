import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lesson_controller.dart';
import '../models/islamic_lesson_model.dart';
import 'widgets/lesson_ui_components.dart';

class LessonDetailScreen extends StatelessWidget {
  final IslamicLesson lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LessonController>();
    final PageController pageController = PageController();
    final visual = LessonIcons.of(lesson.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title, style: const TextStyle(fontFamily: 'cairo')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Obx(() => StepProgressHeader(
              currentStep: controller.currentStepIndex.value,
              totalSteps: lesson.steps.length,
              color: visual.color,
            )),
          ),
          Expanded(
            child: PageView.builder(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lesson.steps.length,
              onPageChanged: (index) => controller.currentStepIndex.value = index,
              itemBuilder: (context, index) {
                final step = lesson.steps[index];
                if (step.type == StepType.summary) {
                  return LessonCompletionView(
                    score: controller.score.value,
                    totalQuestions: lesson.steps.where((s) => s.type == StepType.quiz).length,
                    onFinish: () {
                      controller.markLessonComplete(lesson.id);
                      Navigator.pop(context);
                    },
                  );
                }
                return _buildStepUI(context, step, controller, visual.color);
              },
            ),
          ),
          Obx(() {
            final isSummary = lesson.steps[controller.currentStepIndex.value].type == StepType.summary;
            return isSummary ? const SizedBox.shrink() : _buildNavigationButtons(context, controller, pageController, visual.color);
          }),
        ],
      ),
    );
  }

  Widget _buildStepUI(BuildContext context, LessonStep step, LessonController controller, Color themeColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            style: const TextStyle(fontFamily: 'cairo', fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (step.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(step.imageUrl!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            step.content,
            style: const TextStyle(fontFamily: 'cairo', fontSize: 18, height: 1.6),
          ),
          const SizedBox(height: 30),
          if (step.type == StepType.quiz && step.questions != null)
            ...step.questions!.map((q) => _buildQuizUI(context, q, controller)),
        ],
      ),
    );
  }

  Widget _buildQuizUI(BuildContext context, QuizQuestion question, LessonController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: const TextStyle(fontFamily: 'cairo', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
        const SizedBox(height: 16),
        ...List.generate(question.options.length, (index) {
          return Obx(() {
            return AnswerOptionCard(
              text: question.options[index],
              isSelected: controller.selectedOptionIndex.value == index,
              isCorrectAnswer: controller.quizAnswered.value ? (index == question.correctAnswerIndex) : null,
              showResult: controller.quizAnswered.value,
              onTap: () => controller.submitAnswer(question, index),
            );
          });
        }),
        Obx(() => ExplanationBox(
          explanation: question.explanation,
          isCorrect: controller.isCorrect.value,
          visible: controller.quizAnswered.value,
        )),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context, LessonController controller, PageController pageController, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() => controller.currentStepIndex.value > 0
              ? OutlinedButton(
                  onPressed: () {
                    controller.previousStep();
                    pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: themeColor),
                    foregroundColor: themeColor,
                  ),
                  child: const Text('السابق', style: TextStyle(fontFamily: 'cairo')),
                )
              : const SizedBox.shrink()),
          Obx(() {
            final currentStep = lesson.steps[controller.currentStepIndex.value];
            final bool canGoNext = currentStep.type != StepType.quiz || controller.quizAnswered.value;

            return ElevatedButton(
              onPressed: canGoNext
                  ? () {
                      if (controller.currentStepIndex.value < lesson.steps.length - 1) {
                        controller.nextStep(lesson);
                        pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } else {
                        controller.nextStep(lesson);
                        Navigator.pop(context);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 45),
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                controller.currentStepIndex.value == lesson.steps.length - 1 ? 'إنهاء' : 'التالي',
                style: const TextStyle(fontFamily: 'cairo', fontWeight: FontWeight.bold),
              ),
            );
          }),
        ],
      ),
    );
  }
}
