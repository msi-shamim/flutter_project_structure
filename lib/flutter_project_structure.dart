// lib/flutter_project_structure.dart
library;

import 'dart:io';

import 'package:flutter_project_structure/src/add_path_comments.dart';
import 'package:flutter_project_structure/src/code_metrics.dart';
import 'package:flutter_project_structure/src/dependency_analysis.dart';
import 'package:flutter_project_structure/src/file_statistics.dart';
import 'package:flutter_project_structure/src/todo_comments.dart';
import 'package:path/path.dart' as path;

class FlutterProjectStructure {
  FlutterProjectStructure({
    this.rootDir = 'lib',
    this.outputFile = 'project_structure.md',
    this.includeFileStats = true,
    this.includeTodoComments = true,
    this.includeDependencyAnalysis = true,
    this.includeCodeMetrics = true,
  });

  final String rootDir;
  final String outputFile;
  final bool includeFileStats;
  final bool includeTodoComments;
  final bool includeDependencyAnalysis;
  final bool includeCodeMetrics;

  late final FileStatistics _fileStats;
  late final TodoComments _todoComments;
  late final DependencyAnalysis _dependencyAnalysis;
  late final CodeMetrics _codeMetrics;

  void generate() {
    final libDir = Directory(rootDir);
    if (!libDir.existsSync()) {
      print("Error: '$rootDir' directory not found.");
      return;
    }

    _fileStats = FileStatistics();
    _todoComments = TodoComments();
    _dependencyAnalysis = DependencyAnalysis();
    _codeMetrics = CodeMetrics();

    final projectStructure = StringBuffer();
    projectStructure.writeln('# Project Structure\n');

    _processDirectory(libDir, projectStructure, 0);

    if (includeFileStats) _addProjectStatistics(projectStructure);
    if (includeTodoComments) _addTodoComments(projectStructure);
    if (includeDependencyAnalysis) _addDependencyAnalysis(projectStructure);
    if (includeCodeMetrics) _addCodeMetrics(projectStructure);

    File(outputFile).writeAsStringSync(projectStructure.toString());
    print('Finished processing files.');
    print('Project structure written to $outputFile');
  }

  void _processDirectory(
      Directory dir, StringBuffer projectStructure, int level) {
    final entities = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));

    for (final entity in entities) {
      final relativePath = path.relative(entity.path, from: rootDir);
      final indent = '  ' * level;

      if (entity is File && entity.path.endsWith('.dart')) {
        print('Processing file: ${entity.path}');
        addPathComment(entity);
        projectStructure.writeln('$indent- 📄 `$relativePath`');
        listImports(entity, projectStructure, level + 1);
        _fileStats.updateFileStats(entity);
        _todoComments.findTodoComments(entity);
        _dependencyAnalysis.analyzeDependencies(entity);
        _codeMetrics.analyzeFile(entity);
      } else if (entity is Directory) {
        projectStructure
            .writeln('$indent- 📁 **${path.basename(entity.path)}**');
        _processDirectory(entity, projectStructure, level + 1);
      }
    }
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
}
