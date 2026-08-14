// lib/src/framework_detector.dart
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:yaml/yaml.dart';

import 'file_analyzer.dart';

/// Information about a detected framework.
class FrameworkInfo {
  FrameworkInfo({required this.name, required this.inPubspec})
      : fileEvidence = [];

  final String name;
  final bool inPubspec;
  final List<String> fileEvidence;
}

/// Detects frameworks and libraries used in the project via pubspec
/// dependencies and AST superclass analysis.
class FrameworkDetector implements FileAnalyzer {
  FrameworkDetector(this._pubspecMap);

  final YamlMap? _pubspecMap;
  final Map<String, FrameworkInfo> detectedFrameworks = {};

  /// Package name → framework label mapping.
  static const _packageToFramework = {
    'get': 'GetX',
    'get_storage': 'GetX',
    'flutter_riverpod': 'Riverpod',
    'riverpod': 'Riverpod',
    'hooks_riverpod': 'Riverpod',
    'flutter_bloc': 'Bloc/Cubit',
    'bloc': 'Bloc/Cubit',
    'provider': 'Provider',
    'dio': 'Dio',
    'go_router': 'GoRouter',
    'auto_route': 'AutoRoute',
    'auto_route_generator': 'AutoRoute',
    'freezed': 'Freezed',
    'freezed_annotation': 'Freezed',
    'hive': 'Hive',
    'hive_flutter': 'Hive',
    'drift': 'Drift',
  };

  /// Superclass name → framework label mapping for AST detection.
  static const _superclassToFramework = {
    'GetxController': 'GetX',
    'GetxService': 'GetX',
    'GetView': 'GetX',
    'GetWidget': 'GetX',
    'Bloc': 'Bloc/Cubit',
    'Cubit': 'Bloc/Cubit',
    'StateNotifier': 'Riverpod',
    'AsyncNotifier': 'Riverpod',
    'Notifier': 'Riverpod',
    'ChangeNotifier': 'Provider',
  };

  /// Scan pubspec.yaml dependencies for known frameworks.
  /// Call this once before the pipeline runs.
  void detectFromPubspec() {
    final pubspec = _pubspecMap;
    if (pubspec == null) return;

    for (final section in ['dependencies', 'dev_dependencies']) {
      final deps = pubspec[section];
      if (deps is! YamlMap) continue;

      for (final key in deps.keys) {
        final packageName = key.toString();
        final framework = _packageToFramework[packageName];
        if (framework != null) {
          detectedFrameworks.putIfAbsent(
            framework,
            () => FrameworkInfo(name: framework, inPubspec: true),
          );
        }
      }
    }
  }

  @override
  void analyzeFile(
      File file, String content, CompilationUnit? compilationUnit,
      {required String relativePath}) {
    if (compilationUnit == null) return;

    // AST superclass-based detection
    for (final declaration in compilationUnit.declarations) {
      if (declaration is ClassDeclaration) {
        final superclassName =
            declaration.extendsClause?.superclass.toSource();
        if (superclassName != null) {
          final framework = _superclassToFramework[superclassName];
          if (framework != null) {
            final info = detectedFrameworks.putIfAbsent(
              framework,
              () => FrameworkInfo(name: framework, inPubspec: false),
            );
            if (!info.fileEvidence.contains(relativePath)) {
              info.fileEvidence.add(relativePath);
            }
          }
        }
      }
    }

    // Import-based detection for frameworks without known superclasses
    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective) {
        final uri = directive.uri.stringValue;
        if (uri != null && uri.startsWith('package:')) {
          final packageName = uri.split('/').first.replaceFirst('package:', '');
          final framework = _packageToFramework[packageName];
          if (framework != null) {
            final info = detectedFrameworks.putIfAbsent(
              framework,
              () => FrameworkInfo(name: framework, inPubspec: false),
            );
            if (!info.fileEvidence.contains(relativePath)) {
              info.fileEvidence.add(relativePath);
            }
          }
        }
      }
    }
  }

  @override
  String toString() {
    if (detectedFrameworks.isEmpty) {
      return 'No frameworks or libraries detected.';
    }

    final buffer = StringBuffer();
    buffer.writeln(
        '| Framework | In pubspec | Files using it |');
    buffer.writeln(
        '|-----------|-----------|----------------|');
    for (final info in detectedFrameworks.values) {
      final pubspecLabel = info.inPubspec ? 'Yes' : 'No';
      buffer.writeln(
          '| ${info.name} | $pubspecLabel | ${info.fileEvidence.length} |');
    }
    return buffer.toString();
  }
}
