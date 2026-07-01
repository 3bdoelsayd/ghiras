import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lesson_controller.dart';
import 'lesson_detail_screen.dart';

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
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: CircleAvatar(
                  backgroundColor: Get.theme.primaryColor.withOpacity(0.1),
                  child: Text('${lesson.order}', style: TextStyle(color: Get.theme.primaryColor, fontWeight: FontWeight.bold)),
                ),
                title: Text(
                  lesson.title,
                  style: const TextStyle(fontFamily: 'cairo', fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(lesson.category, style: TextStyle(color: Colors.grey[600], fontFamily: 'cairo')),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: lesson.isCompleted ? 1.0 : 0.0,
                      backgroundColor: Colors.grey[200],
                      color: Colors.green,
                      minHeight: 6,
                    ),
                  ],
                ),
                trailing: Icon(
                  lesson.isCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
                  color: lesson.isCompleted ? Colors.green : Colors.grey,
                ),
                onTap: () {
                  controller.startLesson(lesson);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LessonDetailScreen(lesson: lesson)),
                  );
                },
              ),
            );
          },
        );
      }),
    );
  }
}
