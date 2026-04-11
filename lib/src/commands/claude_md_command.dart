// lib/src/commands/claude_md_command.dart
import 'package:args/command_runner.dart';
import 'package:flutter_project_structure/flutter_project_structure.dart';

/// CLI subcommand that generates a CLAUDE.md file for AI agent context.
class ClaudeMdCommand extends Command<void> {
  ClaudeMdCommand() {
    argParser
      ..addOption('root-dir',
          abbr: 'r', defaultsTo: 'lib', help: 'The root directory to analyze')
      ..addOption('output',
          abbr: 'o', defaultsTo: 'CLAUDE.md', help: 'Output file path');
  }

  @override
  final String name = 'claude-md';

  @override
  final String description = 'Generate a CLAUDE.md file for AI agent context.';

  @override
  void run() {
    final rootDir = argResults!['root-dir'] as String;
    final output = argResults!['output'] as String;

    final structure = FlutterProjectStructure(rootDir: rootDir);
    final context = structure.generate();
    if (context == null) return;

    ClaudeMdGenerator(context).generate(outputPath: output);
    print('CLAUDE.md generated at $output');
  }
}
