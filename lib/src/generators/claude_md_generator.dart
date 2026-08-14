// lib/src/generators/claude_md_generator.dart
import 'dart:io';

import 'package:path/path.dart' as path;

import '../project_context.dart';

/// Generates a CLAUDE.md file optimized for AI agent context consumption.
///
/// Output is detailed markdown (<20KB) with project overview, architecture,
/// directory structure, conventions, dependencies, and code health.
class ClaudeMdGenerator {
  ClaudeMdGenerator(this._context);

  final ProjectContext _context;

  /// Render the CLAUDE.md content as a string.
  String render() {
    final buffer = StringBuffer();

    _writeOverview(buffer);
    _writeArchitecture(buffer);
    _writeDirectoryStructure(buffer);
    _writeConventions(buffer);
    _writeDependencies(buffer);
    _writeCodeHealth(buffer);

    return buffer.toString();
  }

  /// Generate and write CLAUDE.md to disk, returning the path written.
  ///
  /// [outputPath] is used as given (relative paths resolve against the
  /// current directory). When omitted, CLAUDE.md is written to the project
  /// root so it lands with the analyzed project.
  String generate({String? outputPath}) {
    final output = outputPath ??
        path.join(_context.projectRoot, 'CLAUDE.md');
    File(output).writeAsStringSync(render());
    return output;
  }

  void _writeOverview(StringBuffer buffer) {
    buffer.writeln('# Project Context\n');
    buffer.writeln('## Overview\n');

    final typeDetector = _context.projectTypeDetector;
    if (typeDetector != null) {
      buffer.writeln('- **Type:** ${typeDetector.projectType}');
    }

    // Tech stack from detected frameworks
    final frameworkDetector = _context.frameworkDetector;
    if (frameworkDetector != null &&
        frameworkDetector.detectedFrameworks.isNotEmpty) {
      final frameworks =
          frameworkDetector.detectedFrameworks.keys.join(', ');
      buffer.writeln('- **Tech Stack:** $frameworks');
    }

    // Entry points
    final archAnalyzer = _context.architectureAnalyzer;
    if (archAnalyzer != null && archAnalyzer.entryPoints.isNotEmpty) {
      buffer.writeln(
          '- **Entry Points:** ${archAnalyzer.entryPoints.join(', ')}');
    }

    buffer.writeln();
  }

  void _writeArchitecture(StringBuffer buffer) {
    final archAnalyzer = _context.architectureAnalyzer;
    if (archAnalyzer == null || archAnalyzer.layerFiles.isEmpty) return;

    buffer.writeln('## Architecture\n');

    // Layers
    buffer.writeln('### Layers\n');
    final sortedLayers = archAnalyzer.layerFiles.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    for (final entry in sortedLayers) {
      final count = entry.value.length;
      buffer.writeln(
          '- ${entry.key} ($count file${count == 1 ? '' : 's'})');
    }
    buffer.writeln();

    // Layer dependencies
    if (archAnalyzer.layerImports.isNotEmpty) {
      buffer.writeln('### Layer Dependencies\n');
      final sortedImports = archAnalyzer.layerImports.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in sortedImports) {
        final targets = entry.value.toList()..sort();
        buffer.writeln('- ${entry.key} → ${targets.join(', ')}');
      }
      buffer.writeln();
    }
  }

  void _writeDirectoryStructure(StringBuffer buffer) {
    buffer.writeln('## Directory Structure\n');
    buffer.writeln('```');

    // Build compressed tree from file purpose data or file statistics
    final rootDir = Directory(_context.rootDir);
    if (rootDir.existsSync()) {
      _writeDirectoryTree(rootDir, buffer, 0, maxDepth: 3);
    }

    buffer.writeln('```\n');
  }

  void _writeDirectoryTree(
      Directory dir, StringBuffer buffer, int level,
      {int maxDepth = 3}) {
    if (level > maxDepth) return;

    final indent = '  ' * level;
    final dirName = '${path.basename(dir.path)}/';

    final entities = dir.listSync()
      ..sort((a, b) => a.path.compareTo(b.path));

    // Skip macOS resource fork metadata files/directories
    final files = entities
        .whereType<File>()
        .where((f) => !path.basename(f.path).startsWith('._'))
        .toList();
    final dirs = entities
        .whereType<Directory>()
        .where((d) => !path.basename(d.path).startsWith('._'))
        .toList();

    if (level > 0) {
      final dartFileCount =
          files.where((f) => f.path.endsWith('.dart')).length;
      if (dartFileCount > 20) {
        buffer.writeln('$indent$dirName ($dartFileCount files)');
        return;
      }
      buffer.writeln('$indent$dirName');
    } else {
      buffer.writeln('$indent$dirName');
    }

    for (final subDir in dirs) {
      _writeDirectoryTree(subDir, buffer, level + 1, maxDepth: maxDepth);
    }

    // Only show individual files at leaf level or if few files
    if (level >= maxDepth - 1 || files.length <= 10) {
      for (final file in files) {
        if (file.path.endsWith('.dart')) {
          buffer.writeln('$indent  ${path.basename(file.path)}');
        }
      }
    }
  }

  void _writeConventions(StringBuffer buffer) {
    final conventions = _context.conventionAnalyzer;
    if (conventions == null) return;

    buffer.writeln('## Conventions\n');

    if (conventions.fileSuffixCounts.isNotEmpty) {
      final suffixes = conventions.fileSuffixCounts.keys.join(', ');
      buffer.writeln(
          '- File naming: snake_case with suffixes ($suffixes)');
    }

    if (conventions.classSuffixCounts.isNotEmpty) {
      final suffixes = conventions.classSuffixCounts.keys.join(', ');
      buffer.writeln(
          '- Class naming: PascalCase with suffixes ($suffixes)');
    }

    // File purpose summary
    final purposes = _context.filePurposeAnalyzer;
    if (purposes != null && purposes.purposeCounts.isNotEmpty) {
      final sorted = purposes.purposeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final summary =
          sorted.map((e) => '${e.key} (${e.value})').join(', ');
      buffer.writeln('- File purposes: $summary');
    }

    buffer.writeln();
  }

  void _writeDependencies(StringBuffer buffer) {
    final deps = _context.dependencyAnalysis.packageDependencies;
    if (deps.isEmpty) return;

    buffer.writeln('## Dependencies\n');

    // Sort by usage count descending, cap at 15
    final sorted = deps.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    for (final entry in sorted.take(15)) {
      final count = entry.value.length;
      buffer.writeln(
          '- ${entry.key}: $count file${count == 1 ? '' : 's'}');
    }

    buffer.writeln();
  }

  void _writeCodeHealth(StringBuffer buffer) {
    final stats = _context.fileStatistics;
    final aggregator = _context.metricsAggregator;

    buffer.writeln('## Code Health\n');

    buffer.writeln(
        '- ${stats.totalFiles} files, ${stats.totalLines} lines of Dart code');

    if (aggregator != null) {
      buffer.writeln(
          '- ${aggregator.totalClasses} classes, ${aggregator.totalMethods} methods');
      buffer.writeln(
          '- Average ${aggregator.averageLoc.toStringAsFixed(1)} LOC/file, '
          '${aggregator.averageCommentRatio.toStringAsFixed(1)}% comment ratio');
      if (aggregator.filesWithoutComments > 0) {
        buffer.writeln(
            '- ${aggregator.filesWithoutComments} files without comments');
      }
    }

    buffer.writeln();

    // Technical debt
    _writeTechnicalDebt(buffer, aggregator);
  }

  void _writeTechnicalDebt(StringBuffer buffer, dynamic aggregator) {
    final todos = _context.todoComments.todoComments;
    final hasDebt = todos.isNotEmpty ||
        (aggregator != null && aggregator.largestFiles.isNotEmpty);

    if (!hasDebt) return;

    buffer.writeln('### Technical Debt\n');

    if (todos.isNotEmpty) {
      var todoCount = 0;
      var fixmeCount = 0;
      for (final comments in todos.values) {
        for (final comment in comments) {
          if (comment.contains('TODO')) todoCount++;
          if (comment.contains('FIXME')) fixmeCount++;
        }
      }
      final parts = <String>[];
      if (todoCount > 0) parts.add('$todoCount TODO comments');
      if (fixmeCount > 0) parts.add('$fixmeCount FIXME comments');
      buffer.writeln('- ${parts.join(', ')}');
    }

    if (aggregator != null && aggregator.largestFiles.isNotEmpty) {
      final files = (aggregator.largestFiles as List)
          .take(5)
          .map((e) =>
              '${path.basename(e.key)} (${e.value})')
          .join(', ');
      buffer.writeln('- Largest files: $files');
    }

    buffer.writeln();
  }
}
