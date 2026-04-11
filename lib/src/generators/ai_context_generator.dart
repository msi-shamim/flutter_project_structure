// lib/src/generators/ai_context_generator.dart
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../project_context.dart';

/// Generates a `.ai-context/` directory with 6 structured JSON files
/// for programmatic AI agent consumption.
class AiContextGenerator {
  AiContextGenerator(this._context);

  final ProjectContext _context;

  static const _jsonEncoder = JsonEncoder.withIndent('  ');

  /// Generate all 6 JSON files in the output directory.
  void generate({String? outputDir}) {
    final dir = outputDir ??
        path.join(_context.projectRoot, '.ai-context');
    Directory(dir).createSync(recursive: true);

    _writeArchitectureJson(dir);
    _writeFilesJson(dir);
    _writePatternsJson(dir);
    _writeConventionsJson(dir);
    _writeMetricsJson(dir);
    _writeTodosJson(dir);
  }

  void _writeArchitectureJson(String dir) {
    final arch = _context.architectureAnalyzer;
    final typeDetector = _context.projectTypeDetector;

    final data = <String, dynamic>{
      'projectType': typeDetector?.projectType ?? 'unknown',
      'indicators': typeDetector?.indicators ?? [],
      'entryPoints': arch?.entryPoints ?? [],
      'layers': <String, dynamic>{},
      'layerDependencies': <String, dynamic>{},
    };

    if (arch != null) {
      for (final entry in arch.layerFiles.entries) {
        data['layers'][entry.key] = {
          'fileCount': entry.value.length,
          'files': entry.value,
        };
      }
      for (final entry in arch.layerImports.entries) {
        data['layerDependencies'][entry.key] = entry.value.toList()..sort();
      }
    }

    File(path.join(dir, 'architecture.json'))
        .writeAsStringSync(_jsonEncoder.convert(data));
  }

  void _writeFilesJson(String dir) {
    final metrics = _context.codeMetrics.fileMetrics;
    final purposes = _context.filePurposeAnalyzer?.filePurposes ?? {};

    final files = <String, dynamic>{};
    for (final entry in metrics.entries) {
      final m = entry.value;
      files[entry.key] = {
        'purpose': purposes[entry.key] ?? 'unknown',
        'linesOfCode': m.linesOfCode,
        'classes': m.classes,
        'methods': m.methods,
        'commentLines': m.commentLines,
        'commentRatio':
            double.parse(m.commentRatio.toStringAsFixed(1)),
      };
    }

    final data = <String, dynamic>{
      'totalFiles': _context.fileStatistics.totalFiles,
      'files': files,
    };

    File(path.join(dir, 'files.json'))
        .writeAsStringSync(_jsonEncoder.convert(data));
  }

  void _writePatternsJson(String dir) {
    final frameworks =
        _context.frameworkDetector?.detectedFrameworks ?? {};

    final frameworkData = <String, dynamic>{};
    for (final entry in frameworks.entries) {
      final info = entry.value;
      frameworkData[entry.key] = {
        'inPubspec': info.inPubspec,
        'fileCount': info.fileEvidence.length,
        'files': info.fileEvidence,
      };
    }

    final data = <String, dynamic>{
      'frameworks': frameworkData,
    };

    File(path.join(dir, 'patterns.json'))
        .writeAsStringSync(_jsonEncoder.convert(data));
  }

  void _writeConventionsJson(String dir) {
    final conventions = _context.conventionAnalyzer;
    final purposes = _context.filePurposeAnalyzer;

    final data = <String, dynamic>{
      'fileSuffixes':
          conventions?.fileSuffixCounts ?? <String, int>{},
      'classSuffixes':
          conventions?.classSuffixCounts ?? <String, int>{},
      'filePurposes':
          purposes?.purposeCounts ?? <String, int>{},
    };

    File(path.join(dir, 'conventions.json'))
        .writeAsStringSync(_jsonEncoder.convert(data));
  }

  void _writeMetricsJson(String dir) {
    final stats = _context.fileStatistics;
    final aggregator = _context.metricsAggregator;

    final data = <String, dynamic>{
      'summary': {
        'totalFiles': stats.totalFiles,
        'dartFiles': stats.dartFiles,
        'totalLines': stats.totalLines,
        'averageLocPerFile':
            aggregator != null
                ? double.parse(
                    aggregator.averageLoc.toStringAsFixed(1))
                : 0.0,
        'averageCommentRatio':
            aggregator != null
                ? double.parse(
                    aggregator.averageCommentRatio.toStringAsFixed(1))
                : 0.0,
        'totalClasses': aggregator?.totalClasses ?? 0,
        'totalMethods': aggregator?.totalMethods ?? 0,
        'filesWithoutComments':
            aggregator?.filesWithoutComments ?? 0,
      },
      'largestFiles': (aggregator?.largestFiles ?? [])
          .map((e) => {'file': e.key, 'lines': e.value})
          .toList(),
      'smallestFile': stats.smallestFile.isNotEmpty
          ? {'file': stats.smallestFile, 'lines': stats.smallestFileLines}
          : null,
    };

    File(path.join(dir, 'metrics.json'))
        .writeAsStringSync(_jsonEncoder.convert(data));
  }

  void _writeTodosJson(String dir) {
    final todos = _context.todoComments.todoComments;

    var totalCount = 0;
    final items = <String, List<Map<String, dynamic>>>{};

    for (final entry in todos.entries) {
      final fileItems = <Map<String, dynamic>>[];
      for (final comment in entry.value) {
        totalCount++;
        // Parse "Line N: text" format
        final match = RegExp(r'^Line (\d+): (.+)$').firstMatch(comment);
        if (match != null) {
          fileItems.add({
            'line': int.parse(match.group(1)!),
            'text': match.group(2)!,
          });
        } else {
          fileItems.add({'line': 0, 'text': comment});
        }
      }
      items[entry.key] = fileItems;
    }

    final data = <String, dynamic>{
      'totalCount': totalCount,
      'filesAffected': todos.length,
      'items': items,
    };

    File(path.join(dir, 'todos.json'))
        .writeAsStringSync(_jsonEncoder.convert(data));
  }
}
