// lib/src/dependency_analysis.dart
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;

import 'file_analyzer.dart';

/// Analyzes and stores package dependencies for Dart files.
class DependencyAnalysis implements FileAnalyzer {
  final Map<String, Set<String>> packageDependencies = {};

  @override
  void analyzeFile(
      File file, String content, CompilationUnit? compilationUnit) {
    if (compilationUnit == null) return;

    final relativePath = path.join('lib',
        path.relative(file.path, from: path.dirname(path.dirname(file.path))));

    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective) {
        final uri = directive.uri.stringValue!;
        if (uri.startsWith('package:')) {
          final package = uri.split('/')[0].replaceFirst('package:', '');
          packageDependencies.putIfAbsent(package, () => {}).add(relativePath);
        }
      }
    }
  }

  /// Analyzes dependencies for a single Dart file.
  @Deprecated('Use analyzeFile instead')
  void analyzeDependencies(File file) {
    final content = file.readAsStringSync();
    final result =
        parseString(content: content);
    analyzeFile(file, content, result.unit);
  }

  @override
  String toString() {
    if (packageDependencies.isEmpty) {
      return 'No external package dependencies found.';
    }

    final buffer = StringBuffer();
    packageDependencies.forEach((package, files) {
      buffer.writeln('Package: $package');
      buffer.writeln('Used in:');
      for (final file in files) {
        buffer.writeln('  - $file');
      }
      buffer.writeln();
    });
    return buffer.toString();
  }
}
