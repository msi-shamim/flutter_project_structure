// lib/src/code_metrics.dart
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class CodeMetrics {
  final Map<String, FileMetrics> fileMetrics = {};

  void analyzeFile(File file) {
    final content = file.readAsStringSync();
    final result = parseString(content: content);
    final unit = result.unit;

    final visitor = _MetricsVisitor();
    unit.accept(visitor);

    fileMetrics[file.path] = FileMetrics(
      linesOfCode: content.split('\n').length,
      classes: visitor.classes,
      methods: visitor.methods,
      commentLines: visitor.commentLines,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    fileMetrics.forEach((file, metrics) {
      buffer.writeln('File: $file');
      buffer.writeln('  Lines of Code: ${metrics.linesOfCode}');
      buffer.writeln('  Classes: ${metrics.classes}');
      buffer.writeln('  Methods: ${metrics.methods}');
      buffer.writeln('  Comment Lines: ${metrics.commentLines}');
      buffer.writeln(
          '  Comment Ratio: ${metrics.commentRatio.toStringAsFixed(2)}%');
      buffer.writeln();
    });
    return buffer.toString();
  }
}

class FileMetrics {
  FileMetrics({
    required this.linesOfCode,
    required this.classes,
    required this.methods,
    required this.commentLines,
  });
  final int linesOfCode;
  final int classes;
  final int methods;
  final int commentLines;

  double get commentRatio => (commentLines / linesOfCode) * 100;
}

class _MetricsVisitor extends RecursiveAstVisitor<void> {
  int classes = 0;
  int methods = 0;
  int commentLines = 0;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    classes++;
    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    methods++;
    super.visitMethodDeclaration(node);
  }

  @override
  void visitComment(Comment node) {
    commentLines += node.tokens.length;
    super.visitComment(node);
  }
}
