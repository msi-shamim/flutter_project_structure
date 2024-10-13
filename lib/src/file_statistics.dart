// lib/src/file_statistics.dart
import 'dart:io';

import 'package:path/path.dart' as path;

/// Collects and stores statistics about Dart files in the project.
class FileStatistics {
  int totalFiles = 0;
  int dartFiles = 0;
  int totalDirectories = 0;
  int totalLines = 0;
  String largestFile = '';
  int largestFileLines = 0;
  String smallestFile = '';
  int smallestFileLines = 0;

  /// Updates statistics for a single Dart file.
  void updateFileStats(File file) {
    totalFiles++;
    dartFiles++;
    final lines = file.readAsLinesSync();
    final lineCount = lines.length;
    totalLines += lineCount;

    final relativePath = path.join('lib',
        path.relative(file.path, from: path.dirname(path.dirname(file.path))));

    if (lineCount > largestFileLines) {
      largestFileLines = lineCount;
      largestFile = relativePath;
    }

    if (smallestFileLines == 0 || lineCount < smallestFileLines) {
      smallestFileLines = lineCount;
      smallestFile = relativePath;
    }
  }

  @override
  String toString() {
    return '''
- Total Files: $totalFiles
- Dart Files: $dartFiles
- Total Lines of Dart Code: $totalLines
- Largest File: `$largestFile` with $largestFileLines lines
- Smallest File: `$smallestFile` with $smallestFileLines lines
''';
  }
}
