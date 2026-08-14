// lib/src/project_context.dart
import 'architecture_analyzer.dart';
import 'code_metrics.dart';
import 'convention_analyzer.dart';
import 'dependency_analysis.dart';
import 'file_purpose_analyzer.dart';
import 'file_statistics.dart';
import 'framework_detector.dart';
import 'import_graph.dart';
import 'metrics_aggregator.dart';
import 'project_type_detector.dart';
import 'todo_comments.dart';

/// Aggregated results from all analyzers after a complete analysis run.
///
/// Consumed by output generators (ClaudeMdGenerator, AiContextGenerator)
/// and available for programmatic access.
class ProjectContext {
  ProjectContext({
    required this.rootDir,
    required this.projectRoot,
    required this.fileStatistics,
    required this.todoComments,
    required this.dependencyAnalysis,
    required this.codeMetrics,
    this.projectTypeDetector,
    this.frameworkDetector,
    this.architectureAnalyzer,
    this.conventionAnalyzer,
    this.filePurposeAnalyzer,
    this.metricsAggregator,
    this.importGraph,
  });

  /// The root directory that was analyzed (e.g., 'lib').
  final String rootDir;

  /// The project root directory (parent of rootDir, where pubspec.yaml lives).
  final String projectRoot;

  final FileStatistics fileStatistics;
  final TodoComments todoComments;
  final DependencyAnalysis dependencyAnalysis;
  final CodeMetrics codeMetrics;
  final ProjectTypeDetector? projectTypeDetector;
  final FrameworkDetector? frameworkDetector;
  final ArchitectureAnalyzer? architectureAnalyzer;
  final ConventionAnalyzer? conventionAnalyzer;
  final FilePurposeAnalyzer? filePurposeAnalyzer;
  final MetricsAggregator? metricsAggregator;

  /// File-level dependency graph, for blast-radius and reachability queries.
  final ImportGraph? importGraph;
}
