// example/main.dart
import 'dart:io';

import 'package:flutter_project_structure/flutter_project_structure.dart';
import 'package:path/path.dart' as path;

void main() async {
  print('Flutter Project Structure v2.0.0 Example\n');

  // Create a sample project structure
  final projectDir = await createSampleProject();

  // 1. Classic usage: generate markdown + path comments
  print('1. Analyze (generate markdown + path comments):');
  analyzeUsage(projectDir);

  // 2. Read-only analysis: get ProjectContext without modifying files
  print('\n2. Read-only Analysis (no file modification):');
  readOnlyAnalysis(projectDir);

  // 3. Generate CLAUDE.md for AI agents
  print('\n3. Generate CLAUDE.md:');
  generateClaudeMd(projectDir);

  // 4. Generate .ai-context/ JSON files
  print('\n4. Generate .ai-context/ JSON files:');
  generateAiContext(projectDir);

  // Clean up
  projectDir.deleteSync(recursive: true);
}

/// Classic usage: generates project_structure.md and adds path comments.
void analyzeUsage(Directory projectDir) {
  final structure = FlutterProjectStructure(
    rootDir: path.join(projectDir.path, 'lib'),
    outputFile: path.join(projectDir.path, 'project_structure.md'),
    includeFileStats: true,
    includeTodoComments: true,
    includeDependencyAnalysis: true,
    includeCodeMetrics: true,
    includeProjectType: true,
    includeFrameworkDetection: true,
    includeArchitecture: true,
    includeConventions: true,
    includeFilePurpose: true,
    includeMetricsAggregation: true,
  );

  structure.generate();
  print('Generated project_structure.md with all features enabled.');
}

/// Read-only analysis: returns ProjectContext without modifying source files.
void readOnlyAnalysis(Directory projectDir) {
  final structure = FlutterProjectStructure(
    rootDir: path.join(projectDir.path, 'lib'),
  );

  final context = structure.runAnalysis();
  if (context == null) {
    print('Error: could not analyze project.');
    return;
  }

  print('Project type: ${context.projectTypeDetector?.projectType}');
  print('Total files: ${context.fileStatistics.totalFiles}');
  print('Total lines: ${context.fileStatistics.totalLines}');

  final frameworks = context.frameworkDetector?.detectedFrameworks;
  if (frameworks != null && frameworks.isNotEmpty) {
    print('Detected frameworks: ${frameworks.keys.join(', ')}');
  }

  final layers = context.architectureAnalyzer?.layerFiles;
  if (layers != null && layers.isNotEmpty) {
    for (final entry in layers.entries) {
      print('Layer: ${entry.key} (${entry.value.length} files)');
    }
  }

  final aggregator = context.metricsAggregator;
  if (aggregator != null) {
    print('Total classes: ${aggregator.totalClasses}');
    print('Total methods: ${aggregator.totalMethods}');
    print(
        'Average LOC/file: ${aggregator.averageLoc.toStringAsFixed(1)}');
  }
}

/// Generate CLAUDE.md for AI agent context.
void generateClaudeMd(Directory projectDir) {
  final structure = FlutterProjectStructure(
    rootDir: path.join(projectDir.path, 'lib'),
  );

  final context = structure.runAnalysis();
  if (context == null) return;

  final outputPath = path.join(projectDir.path, 'CLAUDE.md');
  ClaudeMdGenerator(context).generate(outputPath: outputPath);
  print('Generated CLAUDE.md at $outputPath');

  // Show a preview
  final content = File(outputPath).readAsStringSync();
  final preview = content.length > 500
      ? '${content.substring(0, 500)}...'
      : content;
  print('\nPreview:\n$preview');
}

/// Generate .ai-context/ directory with 6 JSON files.
void generateAiContext(Directory projectDir) {
  final structure = FlutterProjectStructure(
    rootDir: path.join(projectDir.path, 'lib'),
  );

  final context = structure.runAnalysis();
  if (context == null) return;

  final outputDir = path.join(projectDir.path, '.ai-context');
  AiContextGenerator(context).generate(outputDir: outputDir);
  print('Generated .ai-context/ at $outputDir');

  // List generated files
  final dir = Directory(outputDir);
  if (dir.existsSync()) {
    for (final file in dir.listSync()) {
      print('  - ${path.basename(file.path)}');
    }
  }
}

Future<Directory> createSampleProject() async {
  final projectDir =
      Directory.systemTemp.createTempSync('flutter_project_structure_example_');

  // Create pubspec.yaml
  File(path.join(projectDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: example_app
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  flutter_bloc: ^8.0.0
''');

  // Create lib directory with sample structure
  final libDir = Directory(path.join(projectDir.path, 'lib'))..createSync();
  File(path.join(libDir.path, 'main.dart')).writeAsStringSync('''
import 'package:flutter/material.dart';
import 'widgets/button.dart';

// TODO: Implement app initialization
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: CustomButton(),
        ),
      ),
    );
  }
}
''');

  final widgetsDir = Directory(path.join(libDir.path, 'widgets'))..createSync();
  File(path.join(widgetsDir.path, 'button.dart')).writeAsStringSync('''
import 'package:flutter/material.dart';

// FIXME: Implement proper styling
class CustomButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      child: Text('Click me'),
    );
  }
}
''');

  final modelsDir = Directory(path.join(libDir.path, 'models'))..createSync();
  File(path.join(modelsDir.path, 'user_model.dart')).writeAsStringSync('''
class UserModel {
  final String name;
  final String email;

  UserModel({required this.name, required this.email});
}
''');

  print('Sample project created at: ${projectDir.path}');
  return projectDir;
}
