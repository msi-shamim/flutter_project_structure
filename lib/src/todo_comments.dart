// lib/src/todo_comments.dart
import 'dart:io';

class TodoComments {
  final Map<String, List<String>> todoComments = {};

  void findTodoComments(File file) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.contains('TODO') || line.contains('FIXME')) {
        todoComments
            .putIfAbsent(file.path, () => [])
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
