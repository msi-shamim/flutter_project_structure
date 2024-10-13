// lib/src/file_statistics.dart
import 'dart:io';

import 'package:path/path.dart' as path;

class FileStatistics {
  int totalFiles = 0;
  int dartFiles = 0;
  int totalDirectories = 0;
  int totalLines = 0;
  String largestFile = '';
  int largestFileLines = 0;
  String smallestFile = '';
  int smallestFileLines = 0;

  void updateFileStats(File file) {
    totalFiles++;
    dartFiles++;
    final lines = file.readAsLinesSync();
    final lineCount = lines.length;
    totalLines += lineCount;

    if (lineCount > largestFileLines) {
      largestFileLines = lineCount;
      largestFile = file.path;
    }

    if (smallestFileLines == 0 || lineCount < smallestFileLines) {
      smallestFileLines = lineCount;
      smallestFile = file.path;
    }
  }

  @override
  String toString() {
    return '''
- Total Files: $totalFiles
- Dart Files: $dartFiles
- Total Lines of Dart Code: $totalLines
- Largest File: `${path.basename(largestFile)}` with $largestFileLines lines
- Smallest File: `${path.basename(smallestFile)}` with $smallestFileLines lines
''';
  }
}
