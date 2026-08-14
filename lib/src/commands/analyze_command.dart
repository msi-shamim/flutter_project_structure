// lib/src/commands/analyze_command.dart
import 'package:args/command_runner.dart';
import 'package:flutter_project_structure/flutter_project_structure.dart';

/// The default 'analyze' command that replicates the v1.x CLI behavior.
class AnalyzeCommand extends Command<void> {
  AnalyzeCommand() {
    argParser
      ..addOption('root-dir',
          abbr: 'r', defaultsTo: 'lib', help: 'The root directory to analyze')
      ..addOption('output',
          abbr: 'o',
          help: 'Output file path '
              '(default: project_structure.md in the project root)')
      ..addFlag('file-stats',
          abbr: 'f', defaultsTo: true, help: 'Include file statistics')
      ..addFlag('todo-comments',
          abbr: 't', defaultsTo: true, help: 'Include TODO and FIXME comments')
      ..addFlag('dependency-analysis',
          abbr: 'd', defaultsTo: true, help: 'Include dependency analysis')
      ..addFlag('code-metrics',
          abbr: 'm', defaultsTo: true, help: 'Include code metrics')
      ..addFlag('project-type',
          defaultsTo: true,
          help: 'Detect project type (app/package/plugin/monorepo)')
      ..addFlag('framework-detection',
          defaultsTo: true, help: 'Detect frameworks and libraries')
      ..addFlag('architecture',
          defaultsTo: true, help: 'Analyze architectural layers')
      ..addFlag('conventions',
          defaultsTo: true, help: 'Analyze naming conventions')
      ..addFlag('file-purpose',
          defaultsTo: true, help: 'Classify file purposes')
      ..addFlag('metrics-aggregation',
          defaultsTo: true, help: 'Compute aggregated metrics');
  }

  @override
  final String name = 'analyze';

  @override
  final String description = 'Analyze a Flutter/Dart project structure.';

  @override
  void run() {
    final structure = FlutterProjectStructure(
      rootDir: argResults!['root-dir'] as String,
      outputFile: argResults!['output'] as String?,
      includeFileStats: argResults!['file-stats'] as bool,
      includeTodoComments: argResults!['todo-comments'] as bool,
      includeDependencyAnalysis: argResults!['dependency-analysis'] as bool,
      includeCodeMetrics: argResults!['code-metrics'] as bool,
      includeProjectType: argResults!['project-type'] as bool,
      includeFrameworkDetection: argResults!['framework-detection'] as bool,
      includeArchitecture: argResults!['architecture'] as bool,
      includeConventions: argResults!['conventions'] as bool,
      includeFilePurpose: argResults!['file-purpose'] as bool,
      includeMetricsAggregation: argResults!['metrics-aggregation'] as bool,
    );
    structure.generate();
    print('Project structure generated successfully.');
    print('Output file: ${structure.outputFilePath}');
  }
}
