// lib/src/analysis_pipeline.dart
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';

import 'file_analyzer.dart';

/// Single-pass orchestrator that reads and parses each file once,
/// then distributes the data to all registered analyzers.
class AnalysisPipeline {
  AnalysisPipeline(this._analyzers, {required this.projectRoot});

  final List<FileAnalyzer> _analyzers;

  /// Absolute, normalized path to the directory holding `pubspec.yaml`.
  /// All paths reported by analyzers are computed relative to this.
  final String projectRoot;

  /// Process a single Dart file through all registered analyzers.
  ///
  /// Reads the file once, parses it once, resolves its canonical relative
  /// path once, and passes all three to each analyzer.
  void processFile(File file) {
    try {
      final content = file.readAsStringSync();
      final result = parseString(content: content);
      final unit = result.unit;
      final relativePath = relativePathFor(file, projectRoot);

      for (final analyzer in _analyzers) {
        analyzer.analyzeFile(file, content, unit, relativePath: relativePath);
      }
    } on FormatException catch (e) {
      // Skip files that cannot be decoded as UTF-8 (e.g. macOS ._* metadata)
      print('Skipping ${file.path}: $e');
    } on FileSystemException catch (e) {
      // Skip files with filesystem encoding issues
      print('Skipping ${file.path}: $e');
    }
  }
}
