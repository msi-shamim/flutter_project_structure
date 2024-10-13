// bin/flutter_project_structure.dart
import 'package:args/args.dart';
import 'package:flutter_project_structure/flutter_project_structure.dart';

/// The main entry point for the Flutter Project Structure CLI.
void main(List<String> arguments) {
  // Set up the argument parser with various options and flags
  final parser = ArgParser()
    ..addOption('root-dir',
        abbr: 'r', defaultsTo: 'lib', help: 'The root directory to analyze')
    ..addOption('output',
        abbr: 'o',
        defaultsTo: 'project_structure.md',
        help: 'The output file name')
    ..addFlag('file-stats',
        abbr: 'f', defaultsTo: true, help: 'Include file statistics')
    ..addFlag('todo-comments',
        abbr: 't', defaultsTo: true, help: 'Include TODO and FIXME comments')
    ..addFlag('dependency-analysis',
        abbr: 'd', defaultsTo: true, help: 'Include dependency analysis')
    ..addFlag('code-metrics',
        abbr: 'm', defaultsTo: true, help: 'Include code metrics')
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Show this help message');

  try {
    // Parse the command-line arguments
    final results = parser.parse(arguments);

    // If help flag is set, display usage information and exit
    if (results['help']) {
      print('Usage: dart run flutter_project_structure [options]');
      print(parser.usage);
      return;
    }

    // Extract options and flags from parsed results
    final rootDir = results['root-dir'];
    final outputFile = results['output'];
    final includeFileStats = results['file-stats'];
    final includeTodoComments = results['todo-comments'];
    final includeDependencyAnalysis = results['dependency-analysis'];
    final includeCodeMetrics = results['code-metrics'];

    // Create and configure the FlutterProjectStructure instance
    final projectStructure = FlutterProjectStructure(
      rootDir: rootDir,
      outputFile: outputFile,
      includeFileStats: includeFileStats,
      includeTodoComments: includeTodoComments,
      includeDependencyAnalysis: includeDependencyAnalysis,
      includeCodeMetrics: includeCodeMetrics,
    );

    // Generate the project structure
    projectStructure.generate();

    print('Project structure generated successfully.');
    print('Output file: $outputFile');
  } catch (e) {
    // Handle any errors that occur during execution
    print('Error: $e');
    print('Usage: dart run flutter_project_structure [options]');
    print(parser.usage);
  }
}
