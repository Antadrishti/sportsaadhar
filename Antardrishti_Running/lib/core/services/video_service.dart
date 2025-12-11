import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class VideoService {
  Future<String> saveVideo(File tempFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final videosDir = Directory(join(dir.path, 'videos'));

    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final newPath = join(videosDir.path, fileName);
    final saved = await tempFile.copy(newPath);
    return saved.path;
  }
}