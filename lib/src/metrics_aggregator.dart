// lib/src/metrics_aggregator.dart
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';

import 'code_metrics.dart';
import 'file_analyzer.dart';

/// Computes aggregated project health metrics from FileStatistics
/// and CodeMetrics data.
class MetricsAggregator implements FileAnalyzer {
  MetricsAggregator(this._codeMetrics);

  final CodeMetrics _codeMetrics;

  double averageLoc = 0;
  double averageCommentRatio = 0;
  int totalClasses = 0;
  int totalMethods = 0;
  int filesWithoutComments = 0;
  List<MapEntry<String, int>> largestFiles = [];

  @override
  void analyzeFile(
      File file, String content, CompilationUnit? compilationUnit) {
    // No-op: all data comes from other analyzers after pipeline completes.
  }

  /// Compute aggregated metrics from FileStatistics and CodeMetrics.
  /// Call this after the pipeline has finished processing all files.
  void aggregate() {
    final metrics = _codeMetrics.fileMetrics;
    if (metrics.isEmpty) return;

    var totalLoc = 0;
    var totalCommentLines = 0;

    for (final entry in metrics.entries) {
      final m = entry.value;
      totalLoc += m.linesOfCode;
      totalClasses += m.classes;
      totalMethods += m.methods;
      totalCommentLines += m.commentLines;
      if (m.commentLines == 0) {
        filesWithoutComments++;
      }
    }

    averageLoc = totalLoc / metrics.length;
    averageCommentRatio =
        totalLoc > 0 ? (totalCommentLines / totalLoc) * 100 : 0;

    // Top 5 largest files
    final sorted = metrics.entries.toList()
      ..sort((a, b) => b.value.linesOfCode.compareTo(a.value.linesOfCode));
    largestFiles = sorted
        .take(5)
        .map((e) => MapEntry(e.key, e.value.linesOfCode))
        .toList();
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('- Total Classes: $totalClasses');
    buffer.writeln('- Total Methods: $totalMethods');
    buffer.writeln(
        '- Average LOC per file: ${averageLoc.toStringAsFixed(1)}');
    buffer.writeln(
        '- Average Comment Ratio: ${averageCommentRatio.toStringAsFixed(1)}%');
    buffer.writeln('- Files without comments: $filesWithoutComments');
    buffer.writeln();

    if (largestFiles.isNotEmpty) {
      buffer.writeln('### Largest Files (Top ${largestFiles.length})\n');
      for (var i = 0; i < largestFiles.length; i++) {
        final entry = largestFiles[i];
        buffer.writeln('${i + 1}. `${entry.key}` - ${entry.value} lines');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
