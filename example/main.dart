// example/main.dart
import 'dart:io';

import 'package:flutter_project_structure/flutter_project_structure.dart';
import 'package:path/path.dart' as path;

void main() async {
  print('Flutter Project Structure Example\n');

  // Create a sample project structure
  final projectDir = await createSampleProject();

  // Simple usage
  print('1. Simple Usage (with all features):');
  simpleUsage(projectDir);

  print('\n2. Custom Usage (with selected features):');
  customUsage(projectDir);

  // Clean up
  projectDir.deleteSync(recursive: true);
}

void simpleUsage(Directory projectDir) {
  // Create an instance of FlutterProjectStructure with default settings
  final structure = FlutterProjectStructure(
    rootDir: path.join(projectDir.path, 'lib'),
    outputFile: path.join(projectDir.path, 'project_structure.md'),
    includeFileStats: true,
    includeTodoComments: true,
    includeDependencyAnalysis: true,
    includeCodeMetrics: true,
  );

  // Generate the project structure
  structure.generate();

  print('Project structure has been generated with all features.');
  print('Check the project_structure.md file in the project directory.');

  // Display the generated structure
  final content = File(path.join(projectDir.path, 'project_structure.md'))
      .readAsStringSync();
  print('\nGenerated Project Structure:');
  print(content);
}

void customUsage(Directory projectDir) {
  // Create an instance of FlutterProjectStructure with custom settings
  final customStructure = FlutterProjectStructure(
    rootDir: path.join(projectDir.path, 'src'),
    outputFile: path.join(projectDir.path, 'custom_structure.md'),
    includeFileStats: true,
    includeTodoComments: false,
    includeDependencyAnalysis: true,
    includeCodeMetrics: false,
  );

  // Generate the project structure
  customStructure.generate();

  print('Custom project structure has been generated with selected features.');
  print('Check the custom_structure.md file in the project directory.');

  // Display the generated structure
  final content = File(path.join(projectDir.path, 'custom_structure.md'))
      .readAsStringSync();
  print('\nGenerated Custom Project Structure:');
  print(content);
}

Future<Directory> createSampleProject() async {
  final projectDir =
      Directory.systemTemp.createTempSync('flutter_project_structure_example_');

  // Create lib directory
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

  // Create src directory (for custom usage example)
  final srcDir = Directory(path.join(projectDir.path, 'src'))..createSync();
  File(path.join(srcDir.path, 'utils.dart')).writeAsStringSync('''
import 'dart:math';

class Utils {
  static int generateRandomNumber() {
    return Random().nextInt(100);
  }
}
''');

  print('Sample project created at: ${projectDir.path}');
  return projectDir;
}
