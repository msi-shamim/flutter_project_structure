// lib/src/convention_analyzer.dart
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;

import 'file_analyzer.dart';

/// Analyzes file and class naming conventions across the project.
class ConventionAnalyzer implements FileAnalyzer {
  final Map<String, int> fileSuffixCounts = {};
  final Map<String, int> classSuffixCounts = {};
  int _totalFiles = 0;
  int _filesWithSuffix = 0;

  static const _fileSuffixes = [
    '_model',
    '_service',
    '_controller',
    '_widget',
    '_screen',
    '_page',
    '_bloc',
    '_cubit',
    '_repository',
    '_provider',
    '_state',
    '_event',
    '_view',
    '_helper',
    '_util',
  ];

  static const _classSuffixes = [
    'Model',
    'Service',
    'Controller',
    'Widget',
    'Screen',
    'Page',
    'Bloc',
    'Cubit',
    'Repository',
    'Provider',
    'State',
    'Event',
    'View',
    'Helper',
    'Util',
    'Mixin',
  ];

  @override
  void analyzeFile(File file, String content, CompilationUnit? compilationUnit,
      {required String relativePath}) {
    _totalFiles++;

    // Check file name suffix
    final baseName = path.basenameWithoutExtension(file.path);
    for (final suffix in _fileSuffixes) {
      if (baseName.endsWith(suffix)) {
        fileSuffixCounts[suffix] = (fileSuffixCounts[suffix] ?? 0) + 1;
        _filesWithSuffix++;
        break;
      }
    }

    // Check class name suffixes via AST
    if (compilationUnit == null) return;
    for (final declaration in compilationUnit.declarations) {
      if (declaration is ClassDeclaration) {
        final className = _extractClassName(declaration);
        for (final suffix in _classSuffixes) {
          if (className.endsWith(suffix) && className != suffix) {
            classSuffixCounts[suffix] = (classSuffixCounts[suffix] ?? 0) + 1;
            break;
          }
        }
      }
    }
  }

  /// Extracts class name from a ClassDeclaration source.
  /// Works across all analyzer versions by parsing the source string.
  String _extractClassName(ClassDeclaration declaration) {
    final source = declaration.toSource();
    final match = RegExp(r'(?:abstract\s+)?class\s+(\w+)').firstMatch(source);
    return match?.group(1) ?? '';
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    if (_totalFiles == 0) {
      return 'No files analyzed for conventions.';
    }

    final percentage = _totalFiles > 0
        ? (_filesWithSuffix / _totalFiles * 100).toStringAsFixed(1)
        : '0.0';
    buffer.writeln(
        '- Files following suffix convention: $_filesWithSuffix/$_totalFiles ($percentage%)');
    buffer.writeln();

    if (fileSuffixCounts.isNotEmpty) {
      buffer.writeln('### File Naming Conventions\n');
      buffer.writeln('| Suffix | Count |');
      buffer.writeln('|--------|-------|');
      final sorted = fileSuffixCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sorted) {
        buffer.writeln('| `${entry.key}` | ${entry.value} |');
      }
      buffer.writeln();
    }

    if (classSuffixCounts.isNotEmpty) {
      buffer.writeln('### Class Naming Conventions\n');
      buffer.writeln('| Suffix | Count |');
      buffer.writeln('|--------|-------|');
      final sorted = classSuffixCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sorted) {
        buffer.writeln('| `${entry.key}` | ${entry.value} |');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
