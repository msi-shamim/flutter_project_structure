// lib/src/todo_comments.dart
import 'dart:io';

import 'package:path/path.dart' as path;

/// Finds and stores TODO and FIXME comments in Dart files.
class TodoComments {
  final Map<String, List<String>> todoComments = {};

  /// Finds TODO and FIXME comments in a single Dart file.
  void findTodoComments(File file) {
    final lines = file.readAsLinesSync();
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
