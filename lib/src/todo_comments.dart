// lib/src/todo_comments.dart
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;

import 'file_analyzer.dart';

/// Finds and stores TODO and FIXME comments in Dart files.
class TodoComments implements FileAnalyzer {
  final Map<String, List<String>> todoComments = {};

  @override
  void analyzeFile(
      File file, String content, CompilationUnit? compilationUnit) {
    final lines = LineSplitter.split(content).toList();
    final relativePath = path.join('lib',
        path.relative(file.path, from: path.dirname(path.dirname(file.path))));

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.contains('TODO') || line.contains('FIXME')) {
        todoComments
            .putIfAbsent(relativePath, () => [])
            .add('Line ${i + 1}: $line');
      }
    }
  }

  /// Finds TODO and FIXME comments in a single Dart file.
  @Deprecated('Use analyzeFile instead')
  void findTodoComments(File file) {
    final content = file.readAsStringSync();
    analyzeFile(file, content, null);
  }

  @override
  String toString() {
    if (todoComments.isEmpty) {
      return 'No TODO or FIXME comments found.';
    }

    final buffer = StringBuffer();
    todoComments.forEach((file, comments) {
      buffer.writeln('File: $file');
      for (final comment in comments) {
        buffer.writeln('  - $comment');
      }
      buffer.writeln();
    });
    return buffer.toString();
  }
}
