import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lesson_controller.dart';
import '../models/islamic_lesson_model.dart';

class LessonDetailScreen extends StatelessWidget {
  final IslamicLesson lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LessonController>();
    final PageController pageController = PageController();

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
          Obx(() => LinearProgressIndicator(
            value: (controller.currentStepIndex.value + 1) / lesson.steps.length,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            color: Get.theme.primaryColor,
          )),
          Expanded(
            child: PageView.builder(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lesson.steps.length,
              onPageChanged: (index) => controller.currentStepIndex.value = index,
              itemBuilder: (context, index) {
                final step = lesson.steps[index];
                return _buildStepUI(context, step, controller);
              },
            ),
          ),
          _buildNavigationButtons(context, controller, pageController),
        ],
      ),
    );
  }

  Widget _buildStepUI(BuildContext context, LessonStep step, LessonController controller) {
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
          if (step.type == StepType.summary)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.stars, size: 80, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    'تم بنجاح! نتيجتك: ${controller.score.value}',
                    style: const TextStyle(fontFamily: 'cairo', fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
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
            Color? cardColor;
            if (controller.quizAnswered.value) {
              if (index == question.correctAnswerIndex) {
                cardColor = Colors.green.withOpacity(0.2);
              } else if (index == controller.selectedOptionIndex.value) {
                cardColor = Colors.red.withOpacity(0.2);
              }
            }

            return Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: controller.selectedOptionIndex.value == index ? Colors.blue : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: ListTile(
                title: Text(question.options[index], style: const TextStyle(fontFamily: 'cairo')),
                onTap: () => controller.submitAnswer(question, index),
              ),
            );
          });
        }),
        const SizedBox(height: 16),
        Obx(() => controller.quizAnswered.value
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'تفسير: ${question.explanation}',
                  style: const TextStyle(fontFamily: 'cairo', fontStyle: FontStyle.italic),
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context, LessonController controller, PageController pageController) {
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
                backgroundColor: Get.theme.primaryColor,
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
