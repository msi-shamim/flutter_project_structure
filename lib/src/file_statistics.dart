// lib/src/file_statistics.dart
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';

import 'file_analyzer.dart';

/// Collects and stores statistics about Dart files in the project.
class FileStatistics implements FileAnalyzer {
  int totalFiles = 0;
  int dartFiles = 0;
  int totalDirectories = 0;
  int totalLines = 0;
  String largestFile = '';
  int largestFileLines = 0;
  String smallestFile = '';
  int smallestFileLines = 0;

  @override
  void analyzeFile(File file, String content, CompilationUnit? compilationUnit,
      {required String relativePath}) {
    totalFiles++;
    dartFiles++;
    final lineCount = LineSplitter.split(content).length;
    totalLines += lineCount;

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
