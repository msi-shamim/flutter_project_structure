// lib/src/code_metrics.dart
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'file_analyzer.dart';

/// Analyzes and stores code metrics for Dart files.
class CodeMetrics implements FileAnalyzer {
  final Map<String, FileMetrics> fileMetrics = {};

  @override
  void analyzeFile(
      File file, String content, CompilationUnit? compilationUnit,
      {required String relativePath}) {
    if (compilationUnit == null) return;

    final visitor = _MetricsVisitor();
    compilationUnit.accept(visitor);

    fileMetrics[relativePath] = FileMetrics(
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

/// Stores metrics for a single Dart file.
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

/// AST visitor to collect metrics from a Dart file.
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
