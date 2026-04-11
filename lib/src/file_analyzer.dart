// lib/src/file_analyzer.dart
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';

/// Abstract interface for all file analyzers in the pipeline.
///
/// Analyzers accumulate state across multiple [analyzeFile] calls,
/// then produce a formatted summary via [toString].
abstract class FileAnalyzer {
  /// Process a single Dart file.
  ///
  /// [file] is the original File on disk (used for path computation).
  /// [content] is the already-read file content (avoids redundant reads).
  /// [compilationUnit] is the pre-parsed AST (nullable; analyzers that
  /// need AST access should check for null).
  void analyzeFile(File file, String content, CompilationUnit? compilationUnit);
}
