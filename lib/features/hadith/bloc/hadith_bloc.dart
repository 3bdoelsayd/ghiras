import 'dart:convert';
import 'dart:io' show Platform, HttpHeaders, File;
import 'package:flutter/foundation.dart' show kIsWeb, immutable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart' as dio;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';
import 'package:equatable/equatable.dart';

part 'hadith_event.dart';
part 'hadith_state.dart';

const String baseHadithUrl = "https://raw.githubusercontent.com/A7medSa3ed/Hadith-Database/master/json";

class HadithBloc extends Bloc<HadithEvent, HadithState> {
  HadithBloc() : super(HadithInitial()) {
    on<DownloadHadithBook>((event, emit) async {
      if (kIsWeb) {
        // على الويب لا نحتاج للتحميل، ننتقل مباشرة للجلب
        add(GetHadithBook(filename: event.filename));
        return;
      }

      try {
        var appDir = await path_provider.getTemporaryDirectory();

        if (Platform.isAndroid) {
          await Permission.storage.request();
        }

        await dio.Dio().download(
          "$baseHadithUrl/${event.filename}",
          "${appDir.path}/${event.filename}",
          options: dio.Options(headers: {HttpHeaders.acceptEncodingHeader: "*"}),
          onReceiveProgress: (received, total) {
            if (total != -1) {
              emit(HadithDownloading(
                  "${(received / total * 100).toStringAsFixed(0)}%",
                  event.filename));
            }
          },
        );
        
        add(GetHadithBook(filename: event.filename));
        
      } catch (e) {
        emit(HadithError("Failed to download book: $e"));
      }
    });

    on<GetHadithBook>((event, emit) async {
      emit(HadithLoading());
      try {
        if (kIsWeb) {
          // على الويب نجلب البيانات مباشرة من الرابط
          final response = await dio.Dio().get("$baseHadithUrl/${event.filename}");
          var book = response.data is String ? json.decode(response.data) : response.data;
          List<dynamic> hadiths = book['hadiths'] ?? [];
          emit(HadithFetched(hadiths));
        } else {
          // على الهاتف نقرأ من الملف المحلي
          var appDir = await path_provider.getTemporaryDirectory();
          File file = File("${appDir.path}/${event.filename}");

          if (await file.exists()) {
            String jsonData = await file.readAsString();
            var book = json.decode(jsonData);
            List<dynamic> hadiths = book['hadiths'] ?? [];
            emit(HadithFetched(hadiths));
          } else {
            emit(HadithInitial());
          }
        }
      } catch (e) {
        emit(HadithError("Failed to load book: $e"));
      }
    });
  }
}
