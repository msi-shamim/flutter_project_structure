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

    test('generate returns ProjectContext', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );

      final context = structure.generate();

      expect(context, isNotNull);
      expect(context!.fileStatistics.totalFiles, greaterThan(0));
      expect(context.rootDir, '${tempDir.path}/lib');
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

  group('generateMarkdown', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp
          .createTempSync('flutter_project_structure_md_');
      Directory('${tempDir.path}/lib').createSync();
      File('${tempDir.path}/lib/main.dart')
          .writeAsStringSync('void main() {}');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('returns markdown string without writing files', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );

      final markdown = structure.generateMarkdown();

      expect(markdown, isNotNull);
      expect(markdown, contains('# Project Structure'));
      // Should NOT create the output file
      expect(File('${tempDir.path}/structure.md').existsSync(), isFalse);
    });

    test('does not modify source files', () {
      final file = File('${tempDir.path}/lib/main.dart');
      final original = file.readAsStringSync();

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
      );
      structure.generateMarkdown();

      expect(file.readAsStringSync(), equals(original));
    });

    test('contains all enabled analysis sections', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
      );

      final markdown = structure.generateMarkdown()!;

      expect(markdown, contains('## Project Type'));
      expect(markdown, contains('## Project Statistics'));
      expect(markdown, contains('## Code Metrics'));
      expect(markdown, contains('## Aggregated Metrics'));
    });

    test('returns null for non-existent directory', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/nonexistent',
      );

      final markdown = structure.generateMarkdown();

      expect(markdown, isNull);
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

    test('import-based framework detection finds file evidence', () {
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  dio: ^5.0.0
  go_router: ^14.0.0
''');
      File('${tempDir.path}/lib/main.dart').writeAsStringSync('''
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

class ApiClient {
  final Dio dio = Dio();
}
''');

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
      );
      final context = structure.runAnalysis()!;
      final frameworks = context.frameworkDetector!.detectedFrameworks;

      expect(frameworks['Dio']!.fileEvidence.length, greaterThan(0),
          reason: 'Dio should have file evidence from import detection');
      expect(frameworks['GoRouter']!.fileEvidence.length, greaterThan(0),
          reason: 'GoRouter should have file evidence from import detection');
    });

    test('detects main_*.dart as entry points', () {
      File('${tempDir.path}/lib/main.dart')
          .writeAsStringSync('void main() {}');
      File('${tempDir.path}/lib/main_development.dart')
          .writeAsStringSync('void main() {}');
      File('${tempDir.path}/lib/main_staging.dart')
          .writeAsStringSync('void main() {}');
      File('${tempDir.path}/lib/main_production.dart')
          .writeAsStringSync('void main() {}');

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
      );
      final context = structure.runAnalysis()!;
      final entryPoints = context.architectureAnalyzer!.entryPoints;

      expect(entryPoints.length, equals(4));
      expect(entryPoints.any((e) => e.contains('main.dart')), isTrue);
      expect(
          entryPoints.any((e) => e.contains('main_development.dart')), isTrue);
      expect(entryPoints.any((e) => e.contains('main_staging.dart')), isTrue);
      expect(
          entryPoints.any((e) => e.contains('main_production.dart')), isTrue);
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

    test('generate returns context usable by generators', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );

      // generate() should return context for use with generators
      final context = structure.generate();

      expect(context, isNotNull);
      expect(File('${tempDir.path}/structure.md').existsSync(), isTrue);

      // Use returned context with ClaudeMdGenerator
      final claudePath = '${tempDir.path}/CLAUDE.md';
      ClaudeMdGenerator(context!).generate(outputPath: claudePath);
      expect(File(claudePath).existsSync(), isTrue);

      // Use returned context with AiContextGenerator
      final aiDir = '${tempDir.path}/.ai-context';
      AiContextGenerator(context).generate(outputDir: aiDir);
      expect(Directory(aiDir).existsSync(), isTrue);
    });

    test('generate adds path comments and writes structure', () {
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

  group('._* file filtering', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp
          .createTempSync('flutter_project_structure_filter_');
      Directory('${tempDir.path}/lib').createSync();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('skips macOS ._* metadata files during analysis', () {
      File('${tempDir.path}/lib/main.dart')
          .writeAsStringSync('void main() {}');
      // Create a fake macOS metadata file (binary content)
      File('${tempDir.path}/lib/._main.dart')
          .writeAsBytesSync([0x00, 0x05, 0x16, 0x07, 0x00, 0x02, 0x00]);

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );

      // Should not crash on binary ._* files
      final context = structure.generate();

      expect(context, isNotNull);
      expect(context!.fileStatistics.totalFiles, equals(1),
          reason: '._* files should not be counted');
    });

    test('excludes ._* files from markdown output', () {
      File('${tempDir.path}/lib/main.dart')
          .writeAsStringSync('void main() {}');
      File('${tempDir.path}/lib/._main.dart')
          .writeAsBytesSync([0x00, 0x05, 0x16, 0x07]);

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      );
      structure.generate();

      final content = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(content.contains('._main.dart'), isFalse,
          reason: '._* files should not appear in markdown output');
    });

    test('excludes ._* files from CLAUDE.md directory tree', () {
      File('${tempDir.path}/lib/main.dart')
          .writeAsStringSync('void main() {}');
      File('${tempDir.path}/lib/._main.dart')
          .writeAsBytesSync([0x00, 0x05, 0x16, 0x07]);

      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
      );
      final context = structure.runAnalysis()!;
      final claudeMd = ClaudeMdGenerator(context).render();

      expect(claudeMd.contains('._main.dart'), isFalse,
          reason: '._* files should not appear in CLAUDE.md');
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

    test('generate returns null for non-existent directory', () {
      final structure = FlutterProjectStructure(
        rootDir: '${tempDir.path}/nonexistent',
        outputFile: '${tempDir.path}/structure.md',
      );

      final context = structure.generate();
      expect(context, isNull);
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
