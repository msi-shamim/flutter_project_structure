// lib/src/architecture_analyzer.dart
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;

import 'file_analyzer.dart';
import 'import_graph.dart';

/// Detects architectural layers from directory naming conventions
/// and builds an import dependency graph between layers.
class ArchitectureAnalyzer implements FileAnalyzer {
  ArchitectureAnalyzer({required this.packageName});

  /// The `name:` field from pubspec.yaml, needed to resolve the
  /// `package:<own_name>/...` self-imports most Flutter projects use.
  final String? packageName;

  final Map<String, List<String>> layerFiles = {};
  final Map<String, Set<String>> layerImports = {};
  final List<String> entryPoints = [];

  /// Directory name → architectural layer mapping.
  static const _directoryToLayer = {
    'models': 'Model',
    'model': 'Model',
    'services': 'Service',
    'service': 'Service',
    'controllers': 'Controller',
    'controller': 'Controller',
    'views': 'View',
    'view': 'View',
    'widgets': 'Widget',
    'widget': 'Widget',
    'repositories': 'Repository',
    'repository': 'Repository',
    'providers': 'Provider',
    'provider': 'Provider',
    'blocs': 'Bloc',
    'bloc': 'Bloc',
    'cubits': 'Cubit',
    'cubit': 'Cubit',
    'screens': 'Screen',
    'screen': 'Screen',
    'pages': 'Page',
    'page': 'Page',
    'utils': 'Utility',
    'helpers': 'Utility',
    'core': 'Core',
    'data': 'Data',
    'domain': 'Domain',
    'presentation': 'Presentation',
  };

  @override
  void analyzeFile(
      File file, String content, CompilationUnit? compilationUnit,
      {required String relativePath}) {
    // Detect entry points
    final fileName = path.basename(file.path);
    if (fileName == 'main.dart' ||
        fileName == 'app.dart' ||
        fileName.startsWith('main_')) {
      entryPoints.add(relativePath);
    }

    // Classify this file's layer
    final thisLayer = _classifyPath(relativePath);
    if (thisLayer != null) {
      layerFiles.putIfAbsent(thisLayer, () => []).add(relativePath);
    }

    // Build import graph between layers
    if (compilationUnit != null && thisLayer != null) {
      for (final directive in compilationUnit.directives) {
        if (directive is! ImportDirective) continue;
        final uri = directive.uri.stringValue;
        if (uri == null) continue;

        // Resolves both relative imports and package:<own_name>/... imports;
        // returns null for dart: and genuine third-party packages.
        final resolvedPath =
            resolveProjectImport(uri, relativePath, packageName: packageName);
        if (resolvedPath == null) continue;

        final targetLayer = _classifyPath(resolvedPath);
        if (targetLayer != null && targetLayer != thisLayer) {
          layerImports.putIfAbsent(thisLayer, () => {}).add(targetLayer);
        }
      }
    }
  }

  /// Classify a file path into an architectural layer based on
  /// its directory segments.
  String? _classifyPath(String relativePath) {
    final segments = path.split(relativePath);
    for (final segment in segments) {
      final layer = _directoryToLayer[segment];
      if (layer != null) return layer;
    }
    return null;
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    if (layerFiles.isEmpty && entryPoints.isEmpty) {
      return 'No architectural layers detected.';
    }

    if (layerFiles.isNotEmpty) {
      buffer.writeln('### Detected Layers\n');
      final sortedLayers = layerFiles.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));
      for (final entry in sortedLayers) {
        buffer.writeln(
            '- **${entry.key}** (${entry.value.length} file${entry.value.length == 1 ? '' : 's'})');
      }
      buffer.writeln();
    }

    if (entryPoints.isNotEmpty) {
      buffer.writeln('### Entry Points\n');
      for (final entry in entryPoints) {
        buffer.writeln('- `$entry`');
      }
      buffer.writeln();
    }

    if (layerImports.isNotEmpty) {
      buffer.writeln('### Layer Dependencies\n');
      final sortedImports = layerImports.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in sortedImports) {
        final targets = entry.value.toList()..sort();
        buffer.writeln('- ${entry.key} → ${targets.join(', ')}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
