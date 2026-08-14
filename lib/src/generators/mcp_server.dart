// lib/src/generators/mcp_server.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mcp_dart/mcp_dart.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

import '../../flutter_project_structure.dart';

/// MCP server that exposes project analysis data through 6 queryable tools.
///
/// Connects via stdio JSON-RPC. Optionally watches for file changes
/// and re-analyzes the project automatically.
class McpProjectServer {
  McpProjectServer(this._context, {this.rootDir = 'lib'});

  ProjectContext _context;
  final String rootDir;
  late final McpServer _server;

  static const _jsonEncoder = JsonEncoder.withIndent('  ');

  /// Start the MCP server and connect via stdio.
  ///
  /// If [watch] is true, file changes in [rootDir] will trigger re-analysis.
  Future<void> start({bool watch = false}) async {
    _server = McpServer(
      const Implementation(
        name: 'flutter-project-structure',
        version: '3.0.0',
      ),
      options: const McpServerOptions(
        capabilities: ServerCapabilities(
          tools: ServerCapabilitiesTools(listChanged: true),
        ),
      ),
    );

    _registerTools();

    if (watch) {
      _startWatching();
    }

    final transport = StdioServerTransport();
    await _server.connect(transport);
  }

  void _registerTools() {
    // Tool 1: get_architecture
    _server.registerTool(
      'get_architecture',
      description:
          'Get project architecture: type, layers, dependency graph, entry points.',
      inputSchema: const JsonObject(),
      callback: (args, extra) => _handleGetArchitecture(),
    );

    // Tool 2: get_file_purpose
    _server.registerTool(
      'get_file_purpose',
      description: 'Get the purpose and metrics of a specific file.',
      inputSchema: JsonObject(
        properties: {
          'path': JsonSchema.string(
            description: 'Relative file path (e.g. lib/src/main.dart)',
          ),
        },
        required: const ['path'],
      ),
      callback: (args, extra) => _handleGetFilePurpose(args),
    );

    // Tool 3: get_dependencies
    _server.registerTool(
      'get_dependencies',
      description:
          'Get package dependencies. Optionally filter by package name.',
      inputSchema: JsonObject(
        properties: {
          'package': JsonSchema.string(
            description: 'Filter by package name (optional)',
          ),
        },
      ),
      callback: (args, extra) => _handleGetDependencies(args),
    );

    // Tool 4: get_conventions
    _server.registerTool(
      'get_conventions',
      description:
          'Get detected naming conventions: file suffixes, class suffixes, file purposes.',
      inputSchema: const JsonObject(),
      callback: (args, extra) => _handleGetConventions(),
    );

    // Tool 5: get_todos
    _server.registerTool(
      'get_todos',
      description:
          'Get TODO and FIXME comments. Optionally filter by severity.',
      inputSchema: JsonObject(
        properties: {
          'severity': JsonSchema.string(
            description: 'Filter: "TODO", "FIXME", or "all" (default: "all")',
          ),
        },
      ),
      callback: (args, extra) => _handleGetTodos(args),
    );

    // Tool 6: get_file_graph
    _server.registerTool(
      'get_file_graph',
      description:
          'Query the file dependency graph. With no path, returns a summary '
          '(size, most depended-upon files, unreachable files). With a path, '
          'returns what that file imports, what imports it, and its blast '
          'radius — the transitive set of files a change to it could affect. '
          'Use this to find the minimal set of files relevant to an edit.',
      inputSchema: JsonObject(
        properties: {
          'path': JsonSchema.string(
            description: 'Relative file path (e.g. lib/src/main.dart). '
                'Omit for a whole-graph summary.',
          ),
          'depth': JsonSchema.integer(
            description: 'How far to walk the graph for the blast radius. '
                'Omit for the full transitive closure.',
          ),
        },
      ),
      callback: (args, extra) => _handleGetFileGraph(args),
    );

    // Tool 7: get_file_skeleton
    _server.registerTool(
      'get_file_skeleton',
      description: "Get a file's declarations without their bodies — classes, "
          'constructors, method signatures and fields. Roughly a tenth the '
          'size of reading the file. Use this to learn how to CALL a file; '
          'read the file itself only when you need to CHANGE it, or when the '
          'behaviour inside a body is what matters (Flutter build() methods '
          'carry their meaning in the body, not the signature). Pass several '
          'paths at once to survey a whole area cheaply.',
      inputSchema: JsonObject(
        properties: {
          'paths': JsonSchema.array(
            description: 'Relative file paths to skeletonize.',
            items: JsonSchema.string(),
          ),
          'path': JsonSchema.string(
            description: 'A single relative file path (alternative to paths).',
          ),
        },
      ),
      callback: (args, extra) => _handleGetFileSkeleton(args),
    );

    // Tool 8: get_project_structure
    _server.registerTool(
      'get_project_structure',
      description:
          'Get the full project structure markdown. Returns a summary by '
          'default, or a specific section when requested. Sections: tree, '
          'project_type, frameworks, architecture, statistics, todos, '
          'dependencies, metrics, conventions, file_purposes, '
          'aggregated_metrics.',
      inputSchema: JsonObject(
        properties: {
          'section': JsonSchema.string(
            description: 'Return a specific section: "tree", "project_type", '
                '"frameworks", "architecture", "statistics", "todos", '
                '"dependencies", "metrics", "conventions", '
                '"file_purposes", "aggregated_metrics". '
                'Omit to get a summary of all sections.',
          ),
        },
      ),
      callback: (args, extra) => _handleGetProjectStructure(args),
    );
  }

  CallToolResult _handleGetArchitecture() {
    final arch = _context.architectureAnalyzer;
    final typeDetector = _context.projectTypeDetector;

    final layers = <String, dynamic>{};
    if (arch != null) {
      for (final entry in arch.layerFiles.entries) {
        layers[entry.key] = {
          'fileCount': entry.value.length,
          'files': entry.value,
        };
      }
    }

    final layerDeps = <String, dynamic>{};
    if (arch != null) {
      for (final entry in arch.layerImports.entries) {
        layerDeps[entry.key] = entry.value.toList()..sort();
      }
    }

    final data = {
      'projectType': typeDetector?.projectType ?? 'unknown',
      'indicators': typeDetector?.indicators ?? [],
      'entryPoints': arch?.entryPoints ?? [],
      'layers': layers,
      'layerDependencies': layerDeps,
    };

    return CallToolResult(
      content: [TextContent(text: _jsonEncoder.convert(data))],
    );
  }

  CallToolResult _handleGetFilePurpose(Map<String, dynamic> args) {
    final filePath = path.normalize(args['path'] as String);

    // Try exact match first, then normalized variants
    final purposes = _context.filePurposeAnalyzer?.filePurposes ?? {};
    final metrics = _context.codeMetrics.fileMetrics;

    String? purpose;
    String? matchedKey;

    for (final key in purposes.keys) {
      if (path.normalize(key) == filePath || key == filePath) {
        purpose = purposes[key];
        matchedKey = key;
        break;
      }
    }

    if (purpose == null) {
      return CallToolResult(
        content: [
          TextContent(text: 'File not found in analysis: $filePath'),
        ],
        isError: true,
      );
    }

    final fileMetrics = metrics[matchedKey];
    final data = {
      'path': matchedKey,
      'purpose': purpose,
      if (fileMetrics != null) ...{
        'linesOfCode': fileMetrics.linesOfCode,
        'classes': fileMetrics.classes,
        'methods': fileMetrics.methods,
        'commentLines': fileMetrics.commentLines,
        'commentRatio':
            double.parse(fileMetrics.commentRatio.toStringAsFixed(1)),
      },
    };

    return CallToolResult(
      content: [TextContent(text: _jsonEncoder.convert(data))],
    );
  }

  CallToolResult _handleGetDependencies(Map<String, dynamic> args) {
    final deps = _context.dependencyAnalysis.packageDependencies;
    final packageFilter = args['package'] as String?;

    if (packageFilter != null) {
      final files = deps[packageFilter];
      if (files == null) {
        return CallToolResult(
          content: [
            TextContent(
                text: 'Package not found in dependencies: $packageFilter'),
          ],
          isError: true,
        );
      }

      final data = {
        'package': packageFilter,
        'fileCount': files.length,
        'usedIn': files.toList()..sort(),
      };
      return CallToolResult(
        content: [TextContent(text: _jsonEncoder.convert(data))],
      );
    }

    // Return all dependencies
    final packages = <String, dynamic>{};
    for (final entry in deps.entries) {
      packages[entry.key] = {
        'fileCount': entry.value.length,
        'files': entry.value.toList()..sort(),
      };
    }

    final data = {'packages': packages};
    return CallToolResult(
      content: [TextContent(text: _jsonEncoder.convert(data))],
    );
  }

  CallToolResult _handleGetConventions() {
    final conventions = _context.conventionAnalyzer;
    final purposes = _context.filePurposeAnalyzer;

    final data = {
      'fileSuffixes': conventions?.fileSuffixCounts ?? <String, int>{},
      'classSuffixes': conventions?.classSuffixCounts ?? <String, int>{},
      'filePurposes': purposes?.purposeCounts ?? <String, int>{},
    };

    return CallToolResult(
      content: [TextContent(text: _jsonEncoder.convert(data))],
    );
  }

  CallToolResult _handleGetTodos(Map<String, dynamic> args) {
    final severity = (args['severity'] as String?)?.toUpperCase() ?? 'ALL';
    final todos = _context.todoComments.todoComments;

    var totalCount = 0;
    final items = <String, List<Map<String, dynamic>>>{};
    final lineRegex = RegExp(r'^Line (\d+): (.+)$');

    for (final entry in todos.entries) {
      final fileItems = <Map<String, dynamic>>[];
      for (final comment in entry.value) {
        final match = lineRegex.firstMatch(comment);
        final text = match?.group(2) ?? comment;
        final line = match != null ? int.parse(match.group(1)!) : 0;

        // Determine type
        final isTodo = text.contains('TODO');
        final isFixme = text.contains('FIXME');
        final type = isFixme ? 'FIXME' : (isTodo ? 'TODO' : 'OTHER');

        // Apply severity filter
        if (severity != 'ALL' && type != severity) continue;

        totalCount++;
        fileItems.add({'line': line, 'text': text, 'type': type});
      }
      if (fileItems.isNotEmpty) {
        items[entry.key] = fileItems;
      }
    }

    final data = {
      'totalCount': totalCount,
      'filesAffected': items.length,
      'severity': severity,
      'items': items,
    };

    return CallToolResult(
      content: [TextContent(text: _jsonEncoder.convert(data))],
    );
  }

  CallToolResult _handleGetFileGraph(Map<String, dynamic> args) {
    final graph = _context.importGraph;
    if (graph == null) {
      return CallToolResult(
        content: [TextContent(text: 'Import graph is disabled.')],
        isError: true,
      );
    }

    final requested = args['path'] as String?;
    final depth = args['depth'] as int?;

    // No path → whole-graph summary.
    if (requested == null) {
      final entryPoints =
          _context.architectureAnalyzer?.entryPoints ?? const <String>[];
      final unreachable = graph.unreachableFrom(entryPoints).toList()..sort();

      final data = {
        'nodeCount': graph.files.length,
        'edgeCount': graph.edgeCount,
        'entryPoints': entryPoints,
        'hubs': graph
            .hubs()
            .map((e) => {'file': e.key, 'importedBy': e.value})
            .toList(),
        'unreachableCount': unreachable.length,
        'unreachable': unreachable.take(20).toList(),
        'hint': 'Pass "path" to get one file\'s dependencies, dependents '
            'and blast radius.',
      };
      return CallToolResult(
        content: [TextContent(text: _jsonEncoder.convert(data))],
      );
    }

    final file = _matchFile(requested, graph.files);
    if (file == null) {
      return CallToolResult(
        content: [
          TextContent(text: 'File not found in analysis: $requested'),
        ],
        isError: true,
      );
    }

    final blastRadius = graph.dependentsOf(file, maxDepth: depth).toList()
      ..sort();
    final data = {
      'path': file,
      'imports': (graph.imports[file]?.toList() ?? <String>[])..sort(),
      'importedBy': (graph.importedBy[file]?.toList() ?? <String>[])..sort(),
      'blastRadius': blastRadius,
      'blastRadiusCount': blastRadius.length,
      if (depth != null) 'depth': depth,
    };

    return CallToolResult(
      content: [TextContent(text: _jsonEncoder.convert(data))],
    );
  }

  CallToolResult _handleGetFileSkeleton(Map<String, dynamic> args) {
    final analyzer = _context.skeletonAnalyzer;
    if (analyzer == null) {
      return CallToolResult(
        content: [TextContent(text: 'Skeletons are disabled.')],
        isError: true,
      );
    }

    final requested = <String>[
      if (args['path'] is String) args['path'] as String,
      ...?(args['paths'] as List?)?.whereType<String>(),
    ];

    if (requested.isEmpty) {
      return CallToolResult(
        content: [
          TextContent(
            text: 'Provide "path" or "paths". '
                '${analyzer.skeletons.length} files are available.',
          ),
        ],
        isError: true,
      );
    }

    final known = analyzer.skeletons.keys.toSet();
    final rendered = <String>[];
    final missing = <String>[];

    for (final want in requested) {
      final match = _matchFile(want, known);
      if (match == null) {
        missing.add(want);
      } else {
        rendered.add(analyzer.skeletons[match]!.render());
      }
    }

    if (rendered.isEmpty) {
      return CallToolResult(
        content: [
          TextContent(
              text: 'No files found in analysis: ${missing.join(', ')}'),
        ],
        isError: true,
      );
    }

    final text = StringBuffer(rendered.join('\n'));
    if (missing.isNotEmpty) {
      text.writeln('\nNot found in analysis: ${missing.join(', ')}');
    }

    return CallToolResult(content: [TextContent(text: text.toString())]);
  }

  /// Resolve a user-supplied path against the analyzed file set, tolerating
  /// separator and normalisation differences.
  String? _matchFile(String requested, Set<String> known) {
    final normalized = path.split(path.normalize(requested)).join('/');
    if (known.contains(normalized)) return normalized;
    for (final candidate in known) {
      if (path.equals(candidate, normalized)) return candidate;
    }
    return null;
  }

  CallToolResult _handleGetProjectStructure(Map<String, dynamic> args) {
    final sectionFilter = args['section'] as String?;

    // Generate full markdown in-memory (read-only)
    final structure = FlutterProjectStructure(rootDir: rootDir);
    final markdown = structure.generateMarkdown();
    if (markdown == null) {
      return CallToolResult(
        content: [TextContent(text: 'Failed to generate project structure.')],
        isError: true,
      );
    }

    // Section name → heading mapping
    const sectionHeadings = {
      'project_type': '## Project Type',
      'frameworks': '## Detected Frameworks',
      'architecture': '## Architecture',
      'statistics': '## Project Statistics',
      'todos': '## TODO and FIXME Comments',
      'dependencies': '## Dependency Analysis',
      'metrics': '## Code Metrics',
      'conventions': '## Naming Conventions',
      'file_purposes': '## File Purposes',
      'aggregated_metrics': '## Aggregated Metrics',
    };

    // No filter → return summary with section names and line counts
    if (sectionFilter == null) {
      final lines = markdown.split('\n');
      final sections = <Map<String, dynamic>>[];
      String? currentSection;
      var currentStart = 0;

      for (var i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('## ')) {
          if (currentSection != null) {
            sections.add({
              'section': currentSection,
              'lines': i - currentStart,
            });
          }
          currentSection = lines[i].replaceFirst('## ', '');
          currentStart = i;
        }
      }
      if (currentSection != null) {
        sections.add({
          'section': currentSection,
          'lines': lines.length - currentStart,
        });
      }

      final data = {
        'totalLines': lines.length,
        'totalSize': '${(markdown.length / 1024).toStringAsFixed(1)} KB',
        'sections': sections,
        'hint': 'Use the "section" parameter to retrieve a specific section.',
      };
      return CallToolResult(
        content: [TextContent(text: _jsonEncoder.convert(data))],
      );
    }

    // "tree" is special — it's everything before the first ## heading
    if (sectionFilter == 'tree') {
      final firstHeading = markdown.indexOf('\n## ');
      final tree =
          firstHeading > 0 ? markdown.substring(0, firstHeading) : markdown;
      return CallToolResult(
        content: [TextContent(text: tree.trim())],
      );
    }

    // Look up the requested section
    final heading = sectionHeadings[sectionFilter];
    if (heading == null) {
      return CallToolResult(
        content: [
          TextContent(
            text: 'Unknown section: "$sectionFilter". '
                'Valid sections: tree, ${sectionHeadings.keys.join(', ')}',
          ),
        ],
        isError: true,
      );
    }

    final start = markdown.indexOf('\n$heading\n');
    if (start < 0) {
      return CallToolResult(
        content: [
          TextContent(text: 'Section "$sectionFilter" not found in output.'),
        ],
        isError: true,
      );
    }

    // Find the next ## heading or end of string
    final contentStart = start + 1;
    final nextHeading =
        markdown.indexOf('\n## ', contentStart + heading.length);
    final section = nextHeading > 0
        ? markdown.substring(contentStart, nextHeading)
        : markdown.substring(contentStart);

    return CallToolResult(
      content: [TextContent(text: section.trim())],
    );
  }

  void _startWatching() {
    final watcher = DirectoryWatcher(rootDir);
    Timer? debounceTimer;

    watcher.events.listen((WatchEvent event) {
      if (!event.path.endsWith('.dart')) return;

      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(seconds: 2), () {
        stderr.writeln('[mcp-server] File change detected, re-analyzing...');
        final structure = FlutterProjectStructure(rootDir: rootDir);
        final newContext = structure.generate();
        if (newContext != null) {
          _context = newContext;
          stderr.writeln('[mcp-server] Analysis updated.');
        }
      });
    });
  }
}
