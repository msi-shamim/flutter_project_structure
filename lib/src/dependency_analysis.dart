// lib/src/dependency_analysis.dart
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

class DependencyAnalysis {
  final Map<String, Set<String>> packageDependencies = {};

  void analyzeDependencies(File file) {
    final content = file.readAsStringSync();
    final result = parseString(content: content);
    final unit = result.unit;

    for (final directive in unit.directives) {
      if (directive is ImportDirective) {
        final uri = directive.uri.stringValue!;
        if (uri.startsWith('package:')) {
          final package = uri.split('/')[0].replaceFirst('package:', '');
          packageDependencies.putIfAbsent(package, () => {}).add(file.path);
        }
      }
    }
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
