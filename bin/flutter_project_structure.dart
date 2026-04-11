// bin/flutter_project_structure.dart
import 'package:args/command_runner.dart';
import 'package:flutter_project_structure/src/commands/ai_context_command.dart';
import 'package:flutter_project_structure/src/commands/analyze_command.dart';
import 'package:flutter_project_structure/src/commands/claude_md_command.dart';
import 'package:flutter_project_structure/src/commands/mcp_server_command.dart';

/// The main entry point for the Flutter Project Structure CLI.
void main(List<String> arguments) async {
  final runner = CommandRunner<void>(
    'flutter_project_structure',
    'Analyze and document Flutter/Dart project structure.',
  )
    ..addCommand(AnalyzeCommand())
    ..addCommand(ClaudeMdCommand())
    ..addCommand(AiContextCommand())
    ..addCommand(McpServerCommand());

  // Backward compatibility: if no subcommand is provided (i.e., arguments
  // are empty or start with a flag), prepend 'analyze' so the old CLI
  // syntax continues to work.
  final effectiveArgs = arguments.isEmpty || arguments[0].startsWith('-')
      ? ['analyze', ...arguments]
      : arguments;

  try {
    await runner.run(effectiveArgs);
  } catch (e) {
    print('Error: $e');
    print(runner.usage);
  }
}
