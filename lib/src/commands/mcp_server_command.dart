// lib/src/commands/mcp_server_command.dart
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_project_structure/flutter_project_structure.dart';

/// CLI subcommand that starts an MCP server for AI agent integration.
class McpServerCommand extends Command<void> {
  McpServerCommand() {
    argParser
      ..addOption('root-dir',
          abbr: 'r', defaultsTo: 'lib', help: 'The root directory to analyze')
      ..addFlag('watch',
          abbr: 'w',
          defaultsTo: false,
          help: 'Re-analyze on file changes');
  }

  @override
  final String name = 'mcp-server';

  @override
  final String description = 'Start an MCP server for AI agent integration.';

  @override
  Future<void> run() async {
    final rootDir = argResults!['root-dir'] as String;
    final watch = argResults!['watch'] as bool;

    final structure = FlutterProjectStructure(rootDir: rootDir);
    final context = structure.generate();
    if (context == null) {
      stderr.writeln('Error: could not analyze project at $rootDir');
      return;
    }

    final server = McpProjectServer(context, rootDir: rootDir);
    await server.start(watch: watch);
  }
}
