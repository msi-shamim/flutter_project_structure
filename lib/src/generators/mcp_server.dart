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
        version: '2.0.0',
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

    // Tool 6: get_project_structure
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
            description:
                'Return a specific section: "tree", "project_type", '
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
    final severity =
        (args['severity'] as String?)?.toUpperCase() ?? 'ALL';
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
      final tree = firstHeading > 0
          ? markdown.substring(0, firstHeading)
          : markdown;
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
    final nextHeading = markdown.indexOf('\n## ', contentStart + heading.length);
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
