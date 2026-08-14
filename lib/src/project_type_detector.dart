// lib/src/project_type_detector.dart
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'file_analyzer.dart';

/// Detects the project type: monorepo, plugin, flutter_app, or dart_package.
class ProjectTypeDetector implements FileAnalyzer {
  ProjectTypeDetector(this._pubspecMap);

  final YamlMap? _pubspecMap;
  String _projectType = 'unknown';
  final List<String> _indicators = [];

  /// The detected project type.
  String get projectType => _projectType;

  /// Evidence for the detection.
  List<String> get indicators => List.unmodifiable(_indicators);

  /// Detect the project type by examining project root and pubspec.yaml.
  /// Call this once before the pipeline runs.
  void detect(String projectRoot) {
    _indicators.clear();

    final hasMelosYaml =
        File(path.join(projectRoot, 'melos.yaml')).existsSync();
    if (hasMelosYaml) {
      _indicators.add('Found melos.yaml in project root');
    }

    final pubspecCount = _countPubspecFiles(Directory(projectRoot));
    if (pubspecCount > 1) {
      _indicators
          .add('Found $pubspecCount pubspec.yaml files (monorepo indicator)');
    }

    bool hasFlutterKey = false;
    bool hasPluginKey = false;

    final pubspec = _pubspecMap;
    if (pubspec != null) {
      if (pubspec.containsKey('flutter')) {
        hasFlutterKey = true;
        _indicators.add('Found `flutter` key in pubspec.yaml');

        final flutterSection = pubspec['flutter'];
        if (flutterSection is YamlMap && flutterSection.containsKey('plugin')) {
          hasPluginKey = true;
          _indicators.add('Found `flutter.plugin` key in pubspec.yaml');
        }
      }
    } else {
      _indicators.add('No pubspec.yaml found');
    }

    // Priority: monorepo > plugin > flutter_app > dart_package
    if (hasMelosYaml || pubspecCount > 1) {
      _projectType = 'monorepo';
    } else if (hasPluginKey) {
      _projectType = 'plugin';
    } else if (hasFlutterKey) {
      _projectType = 'flutter_app';
    } else {
      _projectType = 'dart_package';
    }
  }

  int _countPubspecFiles(Directory dir) {
    var count = 0;
    try {
      for (final entity in dir.listSync()) {
        if (entity is File && path.basename(entity.path) == 'pubspec.yaml') {
          count++;
        } else if (entity is Directory) {
          final dirName = path.basename(entity.path);
          if (dirName == '.dart_tool' ||
              dirName == 'build' ||
              dirName == '.git' ||
              dirName == '.fvm') {
            continue;
          }
          count += _countPubspecFiles(entity);
        }
      }
    } catch (_) {
      // Skip directories we can't access
    }
    return count;
  }

  @override
  void analyzeFile(File file, String content, CompilationUnit? compilationUnit,
      {required String relativePath}) {
    // No-op: all detection is done in detect()
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('- **Project Type:** $projectType');
    if (_indicators.isNotEmpty) {
      buffer.writeln('- **Indicators:**');
      for (final indicator in _indicators) {
        buffer.writeln('  - $indicator');
      }
    }
    return buffer.toString();
  }
}
