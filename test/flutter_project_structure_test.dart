// test/flutter_project_structure_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_project_structure/flutter_project_structure.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('FlutterProjectStructure', () {
    late Directory tempDir;
    late File testFile;

    setUp(() {
      tempDir = Directory.systemTemp
          .createTempSync('flutter_project_structure_test_');
      Directory('${tempDir.path}/lib').createSync();
      testFile = File('${tempDir.path}/lib/main.dart');
      testFile.writeAsStringSync('''
// TODO: Implement this function
void main() {
  print('Hello, World!');
}

// FIXME: This is a temporary solution
class TestClass {
  void testMethod() {}
}
''');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('generate creates project structure file', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );

      structure.generate();

      expect(File('${tempDir.path}/structure.md').existsSync(), isTrue);
    });

    test('generate adds path comments to Dart files', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );

      structure.generate();

      final content = testFile.readAsStringSync();
      final expectedPath = path.relative(testFile.path,
          from: path.dirname(path.dirname(testFile.path)));
      final expectedComment = '// Path: $expectedPath';

      expect(content.startsWith(expectedComment), isTrue,
          reason: 'File content does not start with expected comment');
    });

    test('generate includes file statistics', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
        includeFileStats: true,
      );

      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('## Project Statistics'), isTrue);
      expect(content.contains('Total Files:'), isTrue);
      expect(content.contains('Dart Files:'), isTrue);
    });

    test('generate includes TODO and FIXME comments', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
        includeTodoComments: true,
      );

      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('## TODO and FIXME Comments'), isTrue);
      expect(content.contains('TODO: Implement this function'), isTrue);
      expect(content.contains('FIXME: This is a temporary solution'), isTrue);
    });

    test('generate includes dependency analysis', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
        includeDependencyAnalysis: true,
      );

      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('## Dependency Analysis'), isTrue);
    });

    test('generate includes code metrics', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
        includeCodeMetrics: true,
      );

      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('## Code Metrics'), isTrue);
      expect(content.contains('Lines of Code:'), isTrue);
      expect(content.contains('Classes:'), isTrue);
      expect(content.contains('Methods:'), isTrue);
    });

    test('generate respects feature flags', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
        includeFileStats: false,
        includeTodoComments: false,
        includeDependencyAnalysis: false,
        includeCodeMetrics: false,
      );

      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('## Project Statistics'), isFalse);
      expect(content.contains('## TODO and FIXME Comments'), isFalse);
      expect(content.contains('## Dependency Analysis'), isFalse);
      expect(content.contains('## Code Metrics'), isFalse);
    });
  });

  group('Phase 2 Analyzers', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp
          .createTempSync('flutter_project_structure_phase2_');
      Directory('${tempDir.path}/lib').createSync();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('generate detects project type from pubspec.yaml', () {
      // Create a pubspec.yaml with flutter key
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: test_app
flutter:
  uses-material-design: true
dependencies:
  flutter:
    sdk: flutter
''');
      File('${tempDir.path}/lib/main.dart').writeAsStringSync('''
void main() {}
''');

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );
      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('## Project Type'), isTrue);
      expect(content.contains('flutter_app'), isTrue);
    });

    test('generate detects dart_package when no flutter key', () {
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: test_package
dependencies:
  path: ^1.9.0
''');
      File('${tempDir.path}/lib/main.dart').writeAsStringSync('''
void main() {}
''');

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );
      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('dart_package'), isTrue);
    });

    test('generate detects frameworks from pubspec and AST', () {
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter_bloc: ^8.0.0
  dio: ^5.0.0
''');
      File('${tempDir.path}/lib/main.dart').writeAsStringSync('''
class MyBloc extends Bloc {}
''');

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );
      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('## Detected Frameworks'), isTrue);
      expect(content.contains('Bloc/Cubit'), isTrue);
      expect(content.contains('Dio'), isTrue);
    });

    test('generate detects architectural layers', () {
      Directory('${tempDir.path}/lib/models').createSync();
      Directory('${tempDir.path}/lib/services').createSync();
      File('${tempDir.path}/lib/models/user_model.dart')
          .writeAsStringSync('class UserModel {}');
      File('${tempDir.path}/lib/services/api_service.dart')
          .writeAsStringSync('class ApiService {}');

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );
      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('## Architecture'), isTrue);
      expect(content.contains('Model'), isTrue);
      expect(content.contains('Service'), isTrue);
    });

    test('generate detects naming conventions', () {
      Directory('${tempDir.path}/lib/models').createSync();
      File('${tempDir.path}/lib/models/user_model.dart')
          .writeAsStringSync('class UserModel {}');

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );
      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('## Naming Conventions'), isTrue);
      expect(content.contains('_model'), isTrue);
    });

    test('generate classifies file purposes', () {
      File('${tempDir.path}/lib/main.dart').writeAsStringSync('''
void main() {}
''');

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );
      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('## File Purposes'), isTrue);
      expect(content.contains('entry_point'), isTrue);
    });

    test('generate includes aggregated metrics', () {
      File('${tempDir.path}/lib/main.dart').writeAsStringSync('''
// A comment
class MyClass {
  void myMethod() {}
}
''');

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );
      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('## Aggregated Metrics'), isTrue);
      expect(content.contains('Total Classes:'), isTrue);
      expect(content.contains('Total Methods:'), isTrue);
      expect(content.contains('Average LOC per file:'), isTrue);
    });

    test('generate respects new feature flags', () {
      File('${tempDir.path}/lib/main.dart').writeAsStringSync('void main() {}');

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
        includeProjectType: false,
        includeFrameworkDetection: false,
        includeArchitecture: false,
        includeConventions: false,
        includeFilePurpose: false,
        includeMetricsAggregation: false,
      );
      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('## Project Type'), isFalse);
      expect(content.contains('## Detected Frameworks'), isFalse);
      expect(content.contains('## Architecture'), isFalse);
      expect(content.contains('## Naming Conventions'), isFalse);
      expect(content.contains('## File Purposes'), isFalse);
      expect(content.contains('## Aggregated Metrics'), isFalse);
    });
  });

  group('Phase 3 Generators', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp
          .createTempSync('flutter_project_structure_phase3_');
      Directory('${tempDir.path}/lib').createSync();
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter_bloc: ^8.0.0
''');
      File('${tempDir.path}/lib/main.dart').writeAsStringSync('''
// TODO: Add app initialization
void main() {}
class MyApp {}
''');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('runAnalysis returns populated ProjectContext', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
      );
      final context = structure.runAnalysis();

      expect(context, isNotNull);
      expect(context!.fileStatistics.totalFiles, greaterThan(0));
      expect(context.rootDir, '${tempDir.path}/lib');
      expect(context.projectRoot, isNotEmpty);
    });

    test('runAnalysis does not modify source files', () {
      final file = File('${tempDir.path}/lib/main.dart');
      final originalContent = file.readAsStringSync();

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
      );
      structure.runAnalysis();

      final afterContent = file.readAsStringSync();
      expect(afterContent, equals(originalContent),
          reason: 'runAnalysis should not modify source files');
    });

    test('ClaudeMdGenerator produces valid output with expected sections', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
      );
      final context = structure.runAnalysis()!;

      final generator = ClaudeMdGenerator(context);
      final content = generator.render();

      expect(content.contains('# Project Context'), isTrue);
      expect(content.contains('## Overview'), isTrue);
      expect(content.contains('## Code Health'), isTrue);
      expect(content.length, lessThan(20 * 1024),
          reason: 'CLAUDE.md should be under 20KB');
    });

    test('ClaudeMdGenerator writes file to disk', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
      );
      final context = structure.runAnalysis()!;

      final outputPath = '${tempDir.path}/CLAUDE.md';
      ClaudeMdGenerator(context).generate(outputPath: outputPath);

      expect(File(outputPath).existsSync(), isTrue);
      final content = File(outputPath).readAsStringSync();
      expect(content.contains('# Project Context'), isTrue);
    });

    test('AiContextGenerator creates all 6 JSON files', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
      );
      final context = structure.runAnalysis()!;

      final outputDir = '${tempDir.path}/.ai-context';
      AiContextGenerator(context).generate(outputDir: outputDir);

      final expectedFiles = [
        'architecture.json',
        'files.json',
        'patterns.json',
        'conventions.json',
        'metrics.json',
        'todos.json',
      ];

      for (final fileName in expectedFiles) {
        final file = File('$outputDir/$fileName');
        expect(file.existsSync(), isTrue,
            reason: '$fileName should be created');

        // Verify valid JSON
        final content = file.readAsStringSync();
        expect(() => jsonDecode(content), returnsNormally,
            reason: '$fileName should contain valid JSON');
      }
    });

    test('AiContextGenerator JSON contains expected structure', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
      );
      final context = structure.runAnalysis()!;

      final outputDir = '${tempDir.path}/.ai-context';
      AiContextGenerator(context).generate(outputDir: outputDir);

      // Check architecture.json
      final arch = jsonDecode(
          File('$outputDir/architecture.json').readAsStringSync());
      expect(arch['projectType'], isA<String>());
      expect(arch['entryPoints'], isA<List>());

      // Check metrics.json
      final metrics = jsonDecode(
          File('$outputDir/metrics.json').readAsStringSync());
      expect(metrics['summary']['totalFiles'], greaterThan(0));

      // Check todos.json
      final todos = jsonDecode(
          File('$outputDir/todos.json').readAsStringSync());
      expect(todos['totalCount'], greaterThan(0));
    });

    test('generate still works with path comments after refactoring', () {
      final file = File('${tempDir.path}/lib/main.dart');

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );
      structure.generate();

      final content = file.readAsStringSync();
      expect(content.startsWith('// Path:'), isTrue,
          reason: 'generate() should still add path comments');
      expect(File('${tempDir.path}/structure.md').existsSync(), isTrue);
    });
  });

  group('Edge Cases', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp
          .createTempSync('flutter_project_structure_edge_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('empty project with no dart files handles gracefully', () {
      Directory('${tempDir.path}/lib').createSync();
      // No .dart files in lib/

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );
      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('# Project Structure'), isTrue);
      expect(content.contains('Total Files: 0'), isTrue);
    });

    test('plugin detection from pubspec.yaml', () {
      Directory('${tempDir.path}/lib').createSync();
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: my_plugin
flutter:
  plugin:
    platforms:
      android:
        package: com.example.my_plugin
''');
      File('${tempDir.path}/lib/main.dart')
          .writeAsStringSync('void main() {}');

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );
      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('plugin'), isTrue);
    });

    test('project with no TODO/FIXME shows empty section', () {
      Directory('${tempDir.path}/lib').createSync();
      File('${tempDir.path}/lib/clean.dart')
          .writeAsStringSync('class Clean {}\n');

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );
      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('No TODO or FIXME comments found.'), isTrue);
    });

    test('runAnalysis returns correct ProjectContext fields', () {
      Directory('${tempDir.path}/lib').createSync();
      Directory('${tempDir.path}/lib/models').createSync();
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: test_pkg
dependencies:
  provider: ^6.0.0
''');
      File('${tempDir.path}/lib/models/user_model.dart')
          .writeAsStringSync('class UserModel {}');

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
      );
      final context = structure.runAnalysis();

      expect(context, isNotNull);
      expect(context!.projectTypeDetector?.projectType, 'dart_package');
      expect(context.architectureAnalyzer?.layerFiles.containsKey('Model'),
          isTrue);
      expect(context.conventionAnalyzer?.fileSuffixCounts['_model'], 1);
      expect(context.filePurposeAnalyzer?.filePurposes.values,
          contains('model'));
      expect(
          context.frameworkDetector?.detectedFrameworks.containsKey('Provider'),
          isTrue);
    });
  });
}
