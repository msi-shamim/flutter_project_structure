// lib/src/import_graph.dart
import 'dart:collection';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;

import 'file_analyzer.dart';

/// Resolves the URI of an `import`/`export` directive to a canonical
/// project-relative path, or null when it points outside the project.
///
/// [fromPath] must be a canonical project-relative path (see
/// [relativePathFor]). [packageName] is the `name:` field from `pubspec.yaml`.
///
/// A project's own files are usually imported as `package:<own_name>/foo.dart`
/// rather than relatively — the dominant convention in modern Flutter apps.
/// Those URIs map to `lib/foo.dart` by Dart's package layout rules; treating
/// them as external dependencies makes a project look like it has no internal
/// structure at all.
String? resolveProjectImport(
  String uri,
  String fromPath, {
  required String? packageName,
}) {
  if (uri.startsWith('dart:')) return null;

  if (uri.startsWith('package:')) {
    if (packageName == null) return null;
    final prefix = 'package:$packageName/';
    if (!uri.startsWith(prefix)) return null; // a real third-party dependency
    return 'lib/${uri.substring(prefix.length)}';
  }

  // Relative import, resolved against the importing file's directory.
  return path.url.normalize(path.url.join(path.url.dirname(fromPath), uri));
}

/// Builds a file-level dependency graph of the project.
///
/// Nodes are canonical project-relative paths; edges are `import` and `export`
/// directives that resolve to another file inside the project. External
/// packages are deliberately excluded — `DependencyAnalysis` covers those.
///
/// [build] must be called once after the pipeline has seen every file, since
/// edges can only be validated against the full set of known files.
class ImportGraph implements FileAnalyzer {
  ImportGraph({required this.packageName});

  /// The `name:` field from pubspec.yaml, used to recognise self-imports.
  final String? packageName;

  /// file → files it depends on (intra-project only).
  final Map<String, Set<String>> imports = {};

  /// file → files that depend on it. The reverse index of [imports].
  final Map<String, Set<String>> importedBy = {};

  final Map<String, Set<String>> _rawEdges = {};
  final Set<String> _knownFiles = {};

  /// Every file the pipeline analyzed.
  Set<String> get files => UnmodifiableSetView(_knownFiles);

  /// Total number of intra-project edges.
  int get edgeCount =>
      imports.values.fold(0, (sum, targets) => sum + targets.length);

  @override
  void analyzeFile(
      File file, String content, CompilationUnit? compilationUnit,
      {required String relativePath}) {
    _knownFiles.add(relativePath);
    if (compilationUnit == null) return;

    for (final directive in compilationUnit.directives) {
      // All three are "this file depends on that file":
      //  - import: the obvious case
      //  - export: barrel files would otherwise look like leaves
      //  - part:   a part is compiled into its parent, and is referenced
      //            nowhere else — omitting it makes every Bloc state and
      //            every .freezed.dart look like dead code
      final String? uri;
      if (directive is ImportDirective) {
        uri = directive.uri.stringValue;
      } else if (directive is ExportDirective) {
        uri = directive.uri.stringValue;
      } else if (directive is PartDirective) {
        uri = directive.uri.stringValue;
      } else {
        continue;
      }
      if (uri == null) continue;

      final target =
          resolveProjectImport(uri, relativePath, packageName: packageName);
      if (target == null || target == relativePath) continue;

      _rawEdges.putIfAbsent(relativePath, () => {}).add(target);
    }
  }

  /// Validate accumulated edges against the files actually analyzed and
  /// populate [imports] and [importedBy].
  ///
  /// Call once after the pipeline has processed every file.
  void build() {
    imports.clear();
    importedBy.clear();

    for (final entry in _rawEdges.entries) {
      // Drop edges to files outside the analyzed root (e.g. a relative
      // import that escapes lib/, or a generated part not on disk).
      final targets = entry.value.where(_knownFiles.contains).toSet();
      if (targets.isEmpty) continue;

      imports[entry.key] = targets;
      for (final target in targets) {
        importedBy.putIfAbsent(target, () => {}).add(entry.key);
      }
    }
  }

  /// Files that would be affected by a change to [file] — its transitive
  /// dependents, i.e. the blast radius of an edit.
  ///
  /// [maxDepth] limits how far to walk; null walks the whole closure.
  Set<String> dependentsOf(String file, {int? maxDepth}) =>
      _walk(file, importedBy, maxDepth);

  /// Files [file] needs in order to work — its transitive dependencies.
  Set<String> dependenciesOf(String file, {int? maxDepth}) =>
      _walk(file, imports, maxDepth);

  /// Files not reachable from any of [entryPoints] by following imports.
  ///
  /// A strong hint at dead code, though reflection, generated registrations
  /// and dynamic routing can all produce false positives.
  Set<String> unreachableFrom(Iterable<String> entryPoints) {
    final reachable = <String>{};
    final queue = Queue<String>();

    for (final entry in entryPoints) {
      if (_knownFiles.contains(entry) && reachable.add(entry)) {
        queue.add(entry);
      }
    }

    while (queue.isNotEmpty) {
      for (final next in imports[queue.removeFirst()] ?? const <String>{}) {
        if (reachable.add(next)) queue.add(next);
      }
    }

    return _knownFiles.difference(reachable);
  }

  /// The most depended-upon files, most first — changing these is riskiest.
  List<MapEntry<String, int>> hubs({int limit = 5}) {
    final ranked = importedBy.entries
        .map((e) => MapEntry(e.key, e.value.length))
        .toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return ranked.take(limit).toList();
  }

  /// Breadth-first closure of [start] over [edges], excluding [start] itself.
  Set<String> _walk(String start, Map<String, Set<String>> edges, int? depth) {
    final seen = <String>{};
    var frontier = <String>{start};

    for (var level = 0; depth == null || level < depth; level++) {
      final next = <String>{};
      for (final node in frontier) {
        for (final neighbour in edges[node] ?? const <String>{}) {
          if (neighbour != start && seen.add(neighbour)) next.add(neighbour);
        }
      }
      if (next.isEmpty) break;
      frontier = next;
    }

    return seen;
  }

  @override
  String toString() {
    if (_knownFiles.isEmpty) return 'No files analyzed for the import graph.';
    if (imports.isEmpty) {
      return 'No intra-project imports detected '
          '(${_knownFiles.length} files analyzed).';
    }

    final buffer = StringBuffer()
      ..writeln('- Files: ${_knownFiles.length}')
      ..writeln('- Intra-project edges: $edgeCount')
      ..writeln();

    final topHubs = hubs();
    if (topHubs.isNotEmpty) {
      buffer
        ..writeln('### Most Depended-Upon Files\n')
        ..writeln('| File | Imported By |')
        ..writeln('|------|-------------|');
      for (final hub in topHubs) {
        buffer.writeln('| `${hub.key}` | ${hub.value} |');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
