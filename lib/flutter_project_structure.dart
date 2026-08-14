// lib/flutter_project_structure.dart
library;

import 'dart:io';

import 'package:flutter_project_structure/src/add_path_comments.dart';
import 'package:flutter_project_structure/src/analysis_pipeline.dart';
import 'package:flutter_project_structure/src/architecture_analyzer.dart';
import 'package:flutter_project_structure/src/code_metrics.dart';
import 'package:flutter_project_structure/src/convention_analyzer.dart';
import 'package:flutter_project_structure/src/dependency_analysis.dart';
import 'package:flutter_project_structure/src/file_analyzer.dart';
import 'package:flutter_project_structure/src/file_purpose_analyzer.dart';
import 'package:flutter_project_structure/src/file_statistics.dart';
import 'package:flutter_project_structure/src/framework_detector.dart';
import 'package:flutter_project_structure/src/import_graph.dart';
import 'package:flutter_project_structure/src/metrics_aggregator.dart';
import 'package:flutter_project_structure/src/project_context.dart';
import 'package:flutter_project_structure/src/project_type_detector.dart';
import 'package:flutter_project_structure/src/skeleton_analyzer.dart';
import 'package:flutter_project_structure/src/todo_comments.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

export 'src/analysis_pipeline.dart';
export 'src/architecture_analyzer.dart';
export 'src/convention_analyzer.dart';
export 'src/file_analyzer.dart';
export 'src/file_purpose_analyzer.dart';
export 'src/framework_detector.dart';
export 'src/import_graph.dart';
export 'src/generators/ai_context_generator.dart';
export 'src/generators/claude_md_generator.dart';
export 'src/generators/mcp_server.dart';
export 'src/metrics_aggregator.dart';
export 'src/project_context.dart';
export 'src/project_type_detector.dart';
export 'src/skeleton_analyzer.dart';

/// Main class for generating the Flutter project structure.
class FlutterProjectStructure {
  /// Constructs a FlutterProjectStructure instance.
  ///
  /// [rootDir]: The root directory to analyze (default: 'lib').
  /// [outputFile]: Where to write the markdown. Relative paths are resolved
  /// against the current directory; when omitted, it defaults to
  /// `project_structure.md` in the project root (next to `pubspec.yaml`),
  /// so output lands with the analyzed project rather than wherever the
  /// command happened to be run from.
  /// [includeFileStats]: Whether to include file statistics (default: true).
  /// [includeTodoComments]: Whether to include TODO and FIXME comments (default: true).
  /// [includeDependencyAnalysis]: Whether to include dependency analysis (default: true).
  /// [includeCodeMetrics]: Whether to include code metrics (default: true).
  /// [includeProjectType]: Whether to detect project type (default: true).
  /// [includeFrameworkDetection]: Whether to detect frameworks (default: true).
  /// [includeArchitecture]: Whether to analyze architecture (default: true).
  /// [includeConventions]: Whether to analyze naming conventions (default: true).
  /// [includeFilePurpose]: Whether to classify file purposes (default: true).
  /// [includeMetricsAggregation]: Whether to compute aggregated metrics (default: true).
  /// [includeImportGraph]: Whether to build the file dependency graph (default: true).
  /// [includeSkeletons]: Whether to extract per-file API skeletons (default: true).
  FlutterProjectStructure({
    this.rootDir = 'lib',
    this.outputFile,
    this.includeFileStats = true,
    this.includeTodoComments = true,
    this.includeDependencyAnalysis = true,
    this.includeCodeMetrics = true,
    this.includeProjectType = true,
    this.includeFrameworkDetection = true,
    this.includeArchitecture = true,
    this.includeConventions = true,
    this.includeFilePurpose = true,
    this.includeMetricsAggregation = true,
    this.includeImportGraph = true,
    this.includeSkeletons = true,
  });

  final String rootDir;
  final String? outputFile;
  final bool includeFileStats;
  final bool includeTodoComments;
  final bool includeDependencyAnalysis;
  final bool includeCodeMetrics;
  final bool includeProjectType;
  final bool includeFrameworkDetection;
  final bool includeArchitecture;
  final bool includeConventions;
  final bool includeFilePurpose;
  final bool includeMetricsAggregation;
  final bool includeImportGraph;
  final bool includeSkeletons;

  late final FileStatistics _fileStats;
  late final TodoComments _todoComments;
  late final DependencyAnalysis _dependencyAnalysis;
  late final CodeMetrics _codeMetrics;
  late final ProjectTypeDetector _projectTypeDetector;
  late final FrameworkDetector _frameworkDetector;
  late final ArchitectureAnalyzer _architectureAnalyzer;
  late final ConventionAnalyzer _conventionAnalyzer;
  late final FilePurposeAnalyzer _filePurposeAnalyzer;
  late final MetricsAggregator _metricsAggregator;
  late final ImportGraph _importGraph;
  late final SkeletonAnalyzer _skeletonAnalyzer;
  late final AnalysisPipeline _pipeline;

  /// Runs analysis on the project and returns a populated [ProjectContext].
  ///
  /// This is a read-only operation — it does NOT modify source files
  /// (no path comments are added). Use this for generators like
  /// ClaudeMdGenerator and AiContextGenerator.
  ProjectContext? runAnalysis() {
    return _runAnalysis(modifyFiles: false);
  }

  /// Generates the project structure markdown and returns it as a string.
  ///
  /// This is a read-only operation — it does NOT modify source files.
  /// Use this for MCP tools or programmatic access to the full markdown.
  String? generateMarkdown() {
    final libDir = Directory(rootDir);
    if (!libDir.existsSync()) {
      print("Error: '$rootDir' directory not found.");
      return null;
    }

    _initializeAnalyzers();

    final projectStructure = StringBuffer();
    projectStructure.writeln('# Project Structure\n');
    _processDirectory(libDir, projectStructure, 0, modifyFiles: false);

    if (includeMetricsAggregation) _metricsAggregator.aggregate();
    if (includeImportGraph) _importGraph.build();

    if (includeProjectType) _addProjectType(projectStructure);
    if (includeFrameworkDetection) _addFrameworkDetection(projectStructure);
    if (includeArchitecture) _addArchitecture(projectStructure);
    if (includeFileStats) _addProjectStatistics(projectStructure);
    if (includeTodoComments) _addTodoComments(projectStructure);
    if (includeDependencyAnalysis) _addDependencyAnalysis(projectStructure);
    if (includeCodeMetrics) _addCodeMetrics(projectStructure);
    if (includeConventions) _addConventions(projectStructure);
    if (includeFilePurpose) _addFilePurpose(projectStructure);
    if (includeMetricsAggregation) _addMetricsAggregation(projectStructure);
    if (includeImportGraph) _addImportGraph(projectStructure);

    return projectStructure.toString();
  }

  /// Generates the project structure markdown, writes it to the output file,
  /// injects path comments into source files, and returns a [ProjectContext].
  ///
  /// This is the core operation — every CLI command calls this to ensure
  /// path comments and project_structure.md are always produced as baseline.
  ProjectContext? generate() {
    final libDir = Directory(rootDir);
    if (!libDir.existsSync()) {
      print("Error: '$rootDir' directory not found.");
      return null;
    }

    _initializeAnalyzers();

    // Build markdown tree + run pipeline + modify files in one pass
    final projectStructure = StringBuffer();
    projectStructure.writeln('# Project Structure\n');
    _processDirectory(libDir, projectStructure, 0, modifyFiles: true);

    // Post-pipeline aggregation
    if (includeMetricsAggregation) _metricsAggregator.aggregate();
    if (includeImportGraph) _importGraph.build();

    // Append analysis sections
    if (includeProjectType) _addProjectType(projectStructure);
    if (includeFrameworkDetection) _addFrameworkDetection(projectStructure);
    if (includeArchitecture) _addArchitecture(projectStructure);
    if (includeFileStats) _addProjectStatistics(projectStructure);
    if (includeTodoComments) _addTodoComments(projectStructure);
    if (includeDependencyAnalysis) _addDependencyAnalysis(projectStructure);
    if (includeCodeMetrics) _addCodeMetrics(projectStructure);
    if (includeConventions) _addConventions(projectStructure);
    if (includeFilePurpose) _addFilePurpose(projectStructure);
    if (includeMetricsAggregation) _addMetricsAggregation(projectStructure);
    if (includeImportGraph) _addImportGraph(projectStructure);

    File(outputFilePath).writeAsStringSync(projectStructure.toString());
    print('Finished processing files.');
    print('Project structure written to $outputFilePath');

    return _buildProjectContext();
  }

  ProjectContext? _runAnalysis({required bool modifyFiles}) {
    final libDir = Directory(rootDir);
    if (!libDir.existsSync()) {
      print("Error: '$rootDir' directory not found.");
      return null;
    }

    _initializeAnalyzers();

    // Process all files
    final discardBuffer = StringBuffer();
    _processDirectory(libDir, discardBuffer, 0, modifyFiles: modifyFiles);

    // Post-pipeline aggregation
    if (includeMetricsAggregation) _metricsAggregator.aggregate();
    if (includeImportGraph) _importGraph.build();

    return _buildProjectContext();
  }

  void _initializeAnalyzers() {
    // Parse pubspec.yaml once for analyzers that need it
    final projectRoot = _projectRoot;
    YamlMap? pubspecMap;
    final pubspecFile = File(path.join(projectRoot, 'pubspec.yaml'));
    if (pubspecFile.existsSync()) {
      pubspecMap = loadYaml(pubspecFile.readAsStringSync()) as YamlMap?;
    }

    // Instantiate all analyzers
    _fileStats = FileStatistics();
    _todoComments = TodoComments();
    _dependencyAnalysis = DependencyAnalysis();
    _codeMetrics = CodeMetrics();
    // A project refers to its own files as package:<name>/..., so the
    // package name is what makes those imports resolvable.
    final packageName = pubspecMap?['name'] as String?;

    _projectTypeDetector = ProjectTypeDetector(pubspecMap);
    _frameworkDetector = FrameworkDetector(pubspecMap);
    _architectureAnalyzer = ArchitectureAnalyzer(packageName: packageName);
    _conventionAnalyzer = ConventionAnalyzer();
    _filePurposeAnalyzer = FilePurposeAnalyzer();
    _metricsAggregator = MetricsAggregator(_codeMetrics);
    _importGraph = ImportGraph(packageName: packageName);
    _skeletonAnalyzer = SkeletonAnalyzer();

    // Run pre-pipeline detection
    if (includeProjectType) _projectTypeDetector.detect(projectRoot);
    if (includeFrameworkDetection) _frameworkDetector.detectFromPubspec();

    // Build pipeline with enabled analyzers
    final analyzers = <FileAnalyzer>[
      if (includeFileStats) _fileStats,
      if (includeTodoComments) _todoComments,
      if (includeDependencyAnalysis) _dependencyAnalysis,
      if (includeCodeMetrics) _codeMetrics,
      if (includeFrameworkDetection) _frameworkDetector,
      if (includeArchitecture) _architectureAnalyzer,
      if (includeConventions) _conventionAnalyzer,
      if (includeFilePurpose) _filePurposeAnalyzer,
      if (includeImportGraph) _importGraph,
      if (includeSkeletons) _skeletonAnalyzer,
    ];
    _pipeline = AnalysisPipeline(analyzers, projectRoot: projectRoot);
  }

  /// Absolute, normalized path to the directory holding `pubspec.yaml`.
  late final String _projectRoot =
      path.dirname(path.normalize(path.absolute(rootDir)));

  /// The path [generate] writes the markdown to.
  ///
  /// This is [outputFile] when supplied, otherwise `project_structure.md`
  /// in the project root.
  String get outputFilePath =>
      outputFile ?? path.join(_projectRoot, 'project_structure.md');

  ProjectContext _buildProjectContext() {
    return ProjectContext(
      rootDir: rootDir,
      projectRoot: _projectRoot,
      fileStatistics: _fileStats,
      todoComments: _todoComments,
      dependencyAnalysis: _dependencyAnalysis,
      codeMetrics: _codeMetrics,
      projectTypeDetector: includeProjectType ? _projectTypeDetector : null,
      frameworkDetector:
          includeFrameworkDetection ? _frameworkDetector : null,
      architectureAnalyzer:
          includeArchitecture ? _architectureAnalyzer : null,
      conventionAnalyzer: includeConventions ? _conventionAnalyzer : null,
      filePurposeAnalyzer:
          includeFilePurpose ? _filePurposeAnalyzer : null,
      metricsAggregator:
          includeMetricsAggregation ? _metricsAggregator : null,
      importGraph: includeImportGraph ? _importGraph : null,
      skeletonAnalyzer: includeSkeletons ? _skeletonAnalyzer : null,
    );
  }

  /// Recursively processes directories and files, building the project structure.
  void _processDirectory(
      Directory dir, StringBuffer projectStructure, int level,
      {bool modifyFiles = true}) {
    final entities = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));

    for (final entity in entities) {
      // Always render tree paths with forward slashes so the generated
      // markdown is identical on Windows and POSIX.
      final displayPath =
          path.split(path.relative(entity.path, from: rootDir)).join('/');
      final indent = '  ' * level;

      if (entity is File && entity.path.endsWith('.dart')) {
        // Skip macOS resource fork files and other non-Dart metadata
        if (path.basename(entity.path).startsWith('._')) continue;
        if (modifyFiles) {
          print('Processing file: ${entity.path}');
          addPathComment(entity, relativePathFor(entity, _projectRoot));
        }
        projectStructure.writeln('$indent- 📄 `$displayPath`');
        if (modifyFiles) {
          listImports(entity, projectStructure, level + 1);
        }
        _pipeline.processFile(entity);
      } else if (entity is Directory) {
        // Skip macOS resource fork metadata directories
        if (path.basename(entity.path).startsWith('._')) continue;
        projectStructure
            .writeln('$indent- 📁 **${path.basename(entity.path)}**');
        _processDirectory(entity, projectStructure, level + 1,
            modifyFiles: modifyFiles);
      }
    }
  }

  void _addProjectType(StringBuffer projectStructure) {
    projectStructure.writeln('\n## Project Type\n');
    projectStructure.writeln(_projectTypeDetector.toString());
  }

  void _addFrameworkDetection(StringBuffer projectStructure) {
    projectStructure.writeln('\n## Detected Frameworks\n');
    projectStructure.writeln(_frameworkDetector.toString());
  }

  void _addArchitecture(StringBuffer projectStructure) {
    projectStructure.writeln('\n## Architecture\n');
    projectStructure.writeln(_architectureAnalyzer.toString());
  }

  void _addProjectStatistics(StringBuffer projectStructure) {
    projectStructure.writeln('\n## Project Statistics\n');
    projectStructure.writeln(_fileStats.toString());
  }

  void _addTodoComments(StringBuffer projectStructure) {
    projectStructure.writeln('\n## TODO and FIXME Comments\n');
    projectStructure.writeln(_todoComments.toString());
  }

  void _addDependencyAnalysis(StringBuffer projectStructure) {
    projectStructure.writeln('\n## Dependency Analysis\n');
    projectStructure.writeln(_dependencyAnalysis.toString());
  }

  void _addCodeMetrics(StringBuffer projectStructure) {
    projectStructure.writeln('\n## Code Metrics\n');
    projectStructure.writeln(_codeMetrics.toString());
  }

  void _addConventions(StringBuffer projectStructure) {
    projectStructure.writeln('\n## Naming Conventions\n');
    projectStructure.writeln(_conventionAnalyzer.toString());
  }

  void _addFilePurpose(StringBuffer projectStructure) {
    projectStructure.writeln('\n## File Purposes\n');
    projectStructure.writeln(_filePurposeAnalyzer.toString());
  }

  void _addMetricsAggregation(StringBuffer projectStructure) {
    projectStructure.writeln('\n## Aggregated Metrics\n');
    projectStructure.writeln(_metricsAggregator.toString());
  }

  void _addImportGraph(StringBuffer projectStructure) {
    projectStructure.writeln('\n## Import Graph\n');
    projectStructure.writeln(_importGraph.toString());
  }
}
