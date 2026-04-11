// lib/src/file_purpose_analyzer.dart
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;

import 'file_analyzer.dart';

/// Classifies each Dart file's role/purpose based on directory context,
/// file name suffix, and AST class hierarchy.
class FilePurposeAnalyzer implements FileAnalyzer {
  final Map<String, String> filePurposes = {};
  final Map<String, int> purposeCounts = {};

  /// File suffix → purpose mapping.
  static const _suffixToPurpose = {
    '_model': 'model',
    '_service': 'service',
    '_controller': 'controller',
    '_widget': 'widget',
    '_screen': 'screen',
    '_page': 'page',
    '_bloc': 'bloc',
    '_cubit': 'cubit',
    '_repository': 'repository',
    '_provider': 'provider',
    '_state': 'state',
    '_event': 'event',
    '_view': 'view',
    '_helper': 'helper',
    '_util': 'utility',
  };

  /// Superclass → purpose mapping for AST detection.
  static const _superclassToPurpose = {
    'StatelessWidget': 'widget',
    'StatefulWidget': 'widget',
    'State': 'widget',
    'Bloc': 'bloc',
    'Cubit': 'cubit',
    'GetxController': 'controller',
    'GetxService': 'service',
    'GetView': 'widget',
    'ChangeNotifier': 'provider',
    'StateNotifier': 'notifier',
    'AsyncNotifier': 'notifier',
    'Notifier': 'notifier',
  };

  /// Directory name → purpose mapping.
  static const _directoryToPurpose = {
    'models': 'model',
    'model': 'model',
    'services': 'service',
    'service': 'service',
    'controllers': 'controller',
    'controller': 'controller',
    'views': 'view',
    'view': 'view',
    'widgets': 'widget',
    'widget': 'widget',
    'repositories': 'repository',
    'repository': 'repository',
    'screens': 'screen',
    'screen': 'screen',
    'pages': 'page',
    'page': 'page',
    'blocs': 'bloc',
    'bloc': 'bloc',
    'cubits': 'cubit',
    'cubit': 'cubit',
    'utils': 'utility',
    'helpers': 'helper',
    'core': 'core',
  };

  @override
  void analyzeFile(
      File file, String content, CompilationUnit? compilationUnit) {
    final relativePath = path.join('lib',
        path.relative(file.path, from: path.dirname(path.dirname(file.path))));
    final fileName = path.basename(file.path);
    final baseName = path.basenameWithoutExtension(file.path);

    String? purpose;

    // 1. Test file
    if (relativePath.contains('/test/') || fileName.endsWith('_test.dart')) {
      purpose = 'test';
    }

    // 2. Generated file
    if (purpose == null &&
        (fileName.endsWith('.g.dart') || fileName.endsWith('.freezed.dart'))) {
      purpose = 'generated';
    }

    // 3. AST-based superclass detection
    if (purpose == null && compilationUnit != null) {
      for (final declaration in compilationUnit.declarations) {
        if (declaration is ClassDeclaration) {
          final superclassName =
              declaration.extendsClause?.superclass.name2.lexeme;
          if (superclassName != null) {
            purpose = _superclassToPurpose[superclassName];
            if (purpose != null) break;
          }
        }
      }
    }

    // 4. File suffix
    if (purpose == null) {
      for (final entry in _suffixToPurpose.entries) {
        if (baseName.endsWith(entry.key)) {
          purpose = entry.value;
          break;
        }
      }
    }

    // 5. Directory context
    if (purpose == null) {
      final segments = path.split(relativePath);
      for (final segment in segments) {
        purpose = _directoryToPurpose[segment];
        if (purpose != null) break;
      }
    }

    // 6. Entry point
    if (purpose == null && fileName == 'main.dart') {
      purpose = 'entry_point';
    }

    // 7. Default
    purpose ??= 'other';

    filePurposes[relativePath] = purpose;
    purposeCounts[purpose] = (purposeCounts[purpose] ?? 0) + 1;
  }

  @override
  String toString() {
    if (filePurposes.isEmpty) {
      return 'No files analyzed for purpose.';
    }

    final buffer = StringBuffer();

    // Summary table
    buffer.writeln('### Purpose Summary\n');
    buffer.writeln('| Purpose | Count |');
    buffer.writeln('|---------|-------|');
    final sorted = purposeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted) {
      buffer.writeln('| ${entry.key} | ${entry.value} |');
    }
    buffer.writeln();

    // Per-file list (capped at 50 for readability)
    if (filePurposes.length <= 50) {
      buffer.writeln('### File Details\n');
      final sortedFiles = filePurposes.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in sortedFiles) {
        buffer.writeln('- `${entry.key}` → ${entry.value}');
      }
      buffer.writeln();
    } else {
      buffer.writeln(
          '*${filePurposes.length} files analyzed — detailed list omitted for brevity.*');
      buffer.writeln();
    }

    return buffer.toString();
  }
}
