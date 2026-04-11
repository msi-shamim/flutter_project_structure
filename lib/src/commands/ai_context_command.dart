// lib/src/commands/ai_context_command.dart
import 'package:args/command_runner.dart';
import 'package:flutter_project_structure/flutter_project_structure.dart';

/// CLI subcommand that generates .ai-context/ JSON files and CLAUDE.md.
class AiContextCommand extends Command<void> {
  AiContextCommand() {
    argParser
      ..addOption('root-dir',
          abbr: 'r', defaultsTo: 'lib', help: 'The root directory to analyze')
      ..addOption('output-dir',
          abbr: 'o',
          defaultsTo: '.ai-context',
          help: 'Output directory for JSON files');
  }

  @override
  final String name = 'ai-context';

  @override
  final String description =
      'Generate .ai-context/ JSON files and CLAUDE.md for AI tooling.';

  @override
  void run() {
    final rootDir = argResults!['root-dir'] as String;
    final outputDir = argResults!['output-dir'] as String;

    final structure = FlutterProjectStructure(rootDir: rootDir);
    final context = structure.generate();
    if (context == null) return;

    AiContextGenerator(context).generate(outputDir: outputDir);
    print('.ai-context/ generated at $outputDir');

    ClaudeMdGenerator(context).generate();
    print('CLAUDE.md generated.');
  }
}
