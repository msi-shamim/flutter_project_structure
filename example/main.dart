// example/main.dart
import 'dart:io';

import 'package:flutter_project_structure/flutter_project_structure.dart';
import 'package:path/path.dart' as path;

void main() async {
  print('Flutter Project Structure v3.0.0 Example\n');

  // Create a sample project structure
  final projectDir = await createSampleProject();

  // 1. The recommended way: generate() does everything in one pass
  //    - Injects path comments into every Dart file
  //    - Writes project_structure.md
  //    - Returns ProjectContext for generators
  print('1. Full analysis (path comments + project_structure.md + context):');
  fullAnalysis(projectDir);

  // 2. Use the returned context to generate AI outputs
  print('\n2. Generate AI context files:');
  generateAiOutputs(projectDir);

  // 3. Read-only analysis (no file modification) — for CI/CD or previews
  print('\n3. Read-only analysis:');
  readOnlyAnalysis(projectDir);

  // Clean up
  projectDir.deleteSync(recursive: true);
}

/// The recommended pattern: generate() injects path comments, writes
/// project_structure.md, and returns a ProjectContext — all in one pass.
void fullAnalysis(Directory projectDir) {
  final structure = FlutterProjectStructure(
    rootDir: path.join(projectDir.path, 'lib'),
    outputFile: path.join(projectDir.path, 'project_structure.md'),
  );

  // One call does it all
  final context = structure.generate();
  if (context == null) {
    print('Error: could not analyze project.');
    return;
  }

  print('Project type: ${context.projectTypeDetector?.projectType}');
  print('Total files: ${context.fileStatistics.totalFiles}');
  print('Total lines: ${context.fileStatistics.totalLines}');

  final frameworks = context.frameworkDetector?.detectedFrameworks;
  if (frameworks != null && frameworks.isNotEmpty) {
    for (final info in frameworks.values) {
      print('Framework: ${info.name} '
          '(pubspec: ${info.inPubspec}, '
          'files: ${info.fileEvidence.length})');
    }
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
    print('Average LOC/file: ${aggregator.averageLoc.toStringAsFixed(1)}');
  }
}

/// Use the ProjectContext from generate() to create AI outputs.
/// This avoids scanning the project twice.
void generateAiOutputs(Directory projectDir) {
  final structure = FlutterProjectStructure(
    rootDir: path.join(projectDir.path, 'lib'),
    outputFile: path.join(projectDir.path, 'project_structure.md'),
  );

  // generate() returns the context — use it for all generators
  final context = structure.generate();
  if (context == null) return;

  // Generate CLAUDE.md
  final claudePath = path.join(projectDir.path, 'CLAUDE.md');
  ClaudeMdGenerator(context).generate(outputPath: claudePath);
  print('Generated CLAUDE.md at $claudePath');

  // Generate .ai-context/ JSON files
  final contextDir = path.join(projectDir.path, '.ai-context');
  AiContextGenerator(context).generate(outputDir: contextDir);
  print('Generated .ai-context/ at $contextDir');

  // List generated files
  final dir = Directory(contextDir);
  if (dir.existsSync()) {
    for (final file in dir.listSync()) {
      print('  - ${path.basename(file.path)}');
    }
  }

  // Show CLAUDE.md preview
  final content = File(claudePath).readAsStringSync();
  final preview =
      content.length > 500 ? '${content.substring(0, 500)}...' : content;
  print('\nCLAUDE.md preview:\n$preview');
}

/// Read-only analysis: no path comments, no file writes.
/// Useful for CI/CD, previews, or custom tooling.
void readOnlyAnalysis(Directory projectDir) {
  final structure = FlutterProjectStructure(
    rootDir: path.join(projectDir.path, 'lib'),
  );

  // runAnalysis() never modifies files
  final context = structure.runAnalysis();
  if (context == null) {
    print('Error: could not analyze project.');
    return;
  }

  print('Project type: ${context.projectTypeDetector?.projectType}');
  print('Total files: ${context.fileStatistics.totalFiles}');

  // Or get just the markdown string without writing to disk
  final markdown = structure.generateMarkdown();
  if (markdown != null) {
    print('Markdown length: ${markdown.length} characters');
  }
}

Future<Directory> createSampleProject() async {
  final projectDir =
      Directory.systemTemp.createTempSync('flutter_project_structure_example_');

  // Create pubspec.yaml with some frameworks
  File(path.join(projectDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: example_app
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  flutter_bloc: ^8.0.0
  dio: ^5.0.0
  go_router: ^14.0.0
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

  // Environment entry points
  File(path.join(libDir.path, 'main_development.dart')).writeAsStringSync('''
import 'main.dart' as app;
void main() => app.main();
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

  final servicesDir = Directory(path.join(libDir.path, 'services'))
    ..createSync();
  File(path.join(servicesDir.path, 'api_service.dart')).writeAsStringSync('''
import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio();

  Future<dynamic> fetchData(String url) async {
    final response = await _dio.get(url);
    return response.data;
  }
}
''');

  print('Sample project created at: ${projectDir.path}');
  return projectDir;
}
