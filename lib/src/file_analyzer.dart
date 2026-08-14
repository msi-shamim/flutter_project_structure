// lib/src/file_analyzer.dart
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;

/// Abstract interface for all file analyzers in the pipeline.
///
/// Analyzers accumulate state across multiple [analyzeFile] calls,
/// then produce a formatted summary via [toString].
abstract class FileAnalyzer {
  /// Process a single Dart file.
  ///
  /// [file] is the original File on disk (used for base name lookups).
  /// [content] is the already-read file content (avoids redundant reads).
  /// [compilationUnit] is the pre-parsed AST (nullable; analyzers that
  /// need AST access should check for null).
  /// [relativePath] is the canonical project-root-relative path — see
  /// [relativePathFor]. Analyzers must use this for any path they record,
  /// so every generated output refers to files identically.
  void analyzeFile(
    File file,
    String content,
    CompilationUnit? compilationUnit, {
    required String relativePath,
  });
}

/// Computes the canonical path used to identify [file] in all output.
///
/// The path is relative to [projectRoot] (the directory holding
/// `pubspec.yaml`), so it includes the analyzed root directory as its first
/// segment — e.g. `lib/src/widgets/foo_widget.dart`. Separators are always
/// forward slashes, so CLAUDE.md, `.ai-context/*.json` and MCP responses are
/// byte-identical across platforms and directly usable as file references.
///
/// [projectRoot] must be absolute and normalized.
String relativePathFor(File file, String projectRoot) {
  final absolute = path.normalize(file.absolute.path);
  return path.split(path.relative(absolute, from: projectRoot)).join('/');
}
