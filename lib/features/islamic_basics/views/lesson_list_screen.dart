import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lesson_controller.dart';
import 'lesson_detail_screen.dart';
import 'widgets/lesson_ui_components.dart';

class LessonListScreen extends StatelessWidget {
  const LessonListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LessonController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('أساسيات الإسلام', style: TextStyle(fontFamily: 'cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.lessons.length,
          itemBuilder: (context, index) {
            final lesson = controller.lessons[index];
            return LessonCard(
              lessonId: lesson.id,
              title: lesson.title,
              progress: lesson.isCompleted ? 1.0 : 0.0,
              onTap: () {
                controller.startLesson(lesson);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LessonDetailScreen(lesson: lesson)),
                );
              },
            );
          },
        );
      }),
    );
  }
}
