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

      expect(content.startsWith('// Path: lib/main.dart'), isTrue,
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

  group('Output path resolution', () {
    late Directory tempDir;
    late Directory cwdSandbox;
    late String originalCwd;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('flutter_project_structure_op_');
      Directory('${tempDir.path}/lib').createSync(recursive: true);
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync('name: op_pkg\n');
      File('${tempDir.path}/lib/main.dart').writeAsStringSync('void main() {}');

      // Run from an unrelated directory so "project root" and "current
      // directory" are distinguishable — the whole point of this group.
      cwdSandbox = Directory.systemTemp
          .createTempSync('flutter_project_structure_cwd_');
      originalCwd = Directory.current.path;
      Directory.current = cwdSandbox;
    });

    tearDown(() {
      Directory.current = originalCwd;
      tempDir.deleteSync(recursive: true);
      cwdSandbox.deleteSync(recursive: true);
    });

    test('markdown defaults to the project root, not the current directory',
        () {
      FlutterProjectStructure(rootDir: '${tempDir.path}/lib').generate();

      expect(File('${tempDir.path}/project_structure.md').existsSync(), isTrue,
          reason: 'Output should land next to pubspec.yaml');
      expect(File('${cwdSandbox.path}/project_structure.md').existsSync(),
          isFalse,
          reason: 'Output should not be dropped in the current directory');
    });

    test('CLAUDE.md defaults to the project root', () {
      final context =
          FlutterProjectStructure(rootDir: '${tempDir.path}/lib').generate()!;

      final written = ClaudeMdGenerator(context).generate();

      expect(File('${tempDir.path}/CLAUDE.md').existsSync(), isTrue);
      expect(File('${cwdSandbox.path}/CLAUDE.md').existsSync(), isFalse);
      expect(path.equals(written, '${tempDir.path}/CLAUDE.md'), isTrue,
          reason: 'generate() should report where it wrote: $written');
    });

    test('.ai-context/ defaults to the project root', () {
      final context =
          FlutterProjectStructure(rootDir: '${tempDir.path}/lib').generate()!;

      final dir = AiContextGenerator(context).generate();

      expect(
          File('${tempDir.path}/.ai-context/architecture.json').existsSync(),
          isTrue);
      expect(Directory('${cwdSandbox.path}/.ai-context').existsSync(), isFalse);
      expect(path.equals(dir, '${tempDir.path}/.ai-context'), isTrue,
          reason: 'generate() should report where it wrote: $dir');
    });

    test('an explicit relative path still resolves against the cwd', () {
      FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: 'custom_structure.md',
      ).generate();

      expect(File('${cwdSandbox.path}/custom_structure.md').existsSync(), isTrue,
          reason: 'An explicitly passed relative path is standard CLI '
              'behaviour and must not be redirected to the project root');
      expect(File('${tempDir.path}/custom_structure.md').existsSync(), isFalse);
    });

    test('outputFilePath reports where the markdown will be written', () {
      final byDefault =
          FlutterProjectStructure(rootDir: '${tempDir.path}/lib');
      final explicit = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: 'explicit.md',
      );

      expect(
          path.equals(byDefault.outputFilePath,
              '${tempDir.path}/project_structure.md'),
          isTrue,
          reason: 'Got: ${byDefault.outputFilePath}');
      expect(explicit.outputFilePath, 'explicit.md',
          reason: 'An explicit value should be passed through untouched');
    });
  });

  group('Nested file paths', () {
    late Directory tempDir;

    // A deliberately deep tree: every reported path must keep all of its
    // intermediate segments, not just the file's immediate parent.
    const nested = 'lib/src/features/auth/widgets/login_button_widget.dart';

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('flutter_project_structure_np_');
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: nested_pkg
dependencies:
  provider: ^6.0.0
''');
      Directory('${tempDir.path}/lib/src/features/auth/widgets')
          .createSync(recursive: true);
      Directory('${tempDir.path}/lib/models').createSync(recursive: true);

      File('${tempDir.path}/lib/main.dart').writeAsStringSync('void main() {}');
      File('${tempDir.path}/$nested').writeAsStringSync('''
// TODO: nested todo
import 'package:provider/provider.dart';

class LoginButtonWidget {}
''');
      File('${tempDir.path}/lib/models/user_model.dart')
          .writeAsStringSync('class UserModel {}');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    ProjectContext analyze() {
      final context =
          FlutterProjectStructure(rootDir: '${tempDir.path}/lib').runAnalysis();
      expect(context, isNotNull);
      return context!;
    }

    test('path comment preserves every intermediate directory', () {
      FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      ).generate();

      final content = File('${tempDir.path}/$nested').readAsStringSync();

      expect(content.startsWith('// Path: $nested\n'), isTrue,
          reason: 'Expected "// Path: $nested" but file starts with: '
              '${content.split('\n').first}');
    });

    test('code metrics key the file by its full relative path', () {
      expect(analyze().codeMetrics.fileMetrics.keys, contains(nested));
    });

    test('file purposes key the file by its full relative path', () {
      final purposes = analyze().filePurposeAnalyzer!.filePurposes;

      expect(purposes.keys, contains(nested));
      expect(purposes[nested], 'widget');
    });

    test('architecture layers record the full relative path', () {
      final arch = analyze().architectureAnalyzer!;

      expect(arch.layerFiles['Widget'], contains(nested));
      expect(arch.entryPoints, contains('lib/main.dart'));
    });

    test('todo comments key the file by its full relative path', () {
      expect(analyze().todoComments.todoComments.keys, contains(nested));
    });

    test('dependency analysis records the full relative path', () {
      expect(analyze().dependencyAnalysis.packageDependencies['provider'],
          contains(nested));
    });

    test('framework detection evidence uses the full relative path', () {
      final frameworks = analyze().frameworkDetector!.detectedFrameworks;

      expect(frameworks['Provider']!.fileEvidence, contains(nested));
    });

    test('file statistics record the full relative path', () {
      final stats = analyze().fileStatistics;

      expect(stats.largestFile, nested,
          reason: 'The nested file is the longest in this fixture');
    });

    test('no reported path is doubled or truncated', () {
      final context = analyze();

      final allPaths = <String>{
        ...context.codeMetrics.fileMetrics.keys,
        ...context.filePurposeAnalyzer!.filePurposes.keys,
        ...context.architectureAnalyzer!.entryPoints,
        ...context.architectureAnalyzer!.layerFiles.values.expand((e) => e),
        ...context.todoComments.todoComments.keys,
        ...context.dependencyAnalysis.packageDependencies.values
            .expand((e) => e),
      };

      expect(allPaths, isNotEmpty);
      for (final p in allPaths) {
        expect(p, startsWith('lib/'),
            reason: '"$p" should be relative to the project root');
        expect(p, isNot(startsWith('lib/lib/')),
            reason: '"$p" has a doubled root segment');
        expect(p, isNot(contains(r'\')),
            reason: '"$p" must use forward slashes on every platform');
        expect(File(path.join(tempDir.path, p)).existsSync(), isTrue,
            reason: '"$p" does not resolve to a real file on disk');
      }
    });

    test('generated markdown and JSON refer to the file identically', () {
      final context = FlutterProjectStructure(
        rootDir: '${tempDir.path}/lib',
        outputFile: '${tempDir.path}/structure.md',
      ).generate()!;

      final markdown = File('${tempDir.path}/structure.md').readAsStringSync();
      expect(markdown, contains(nested));
      expect(markdown, isNot(contains('lib/lib/')));

      AiContextGenerator(context)
          .generate(outputDir: '${tempDir.path}/.ai-context');
      final filesJson = jsonDecode(
              File('${tempDir.path}/.ai-context/files.json').readAsStringSync())
          as Map<String, dynamic>;

      expect((filesJson['files'] as Map).keys, contains(nested));
    });
  });

  group('resolveProjectImport', () {
    test('maps a package: self-import to its lib/ path', () {
      expect(
          resolveProjectImport('package:my_app/core/colors.dart', 'lib/a.dart',
              packageName: 'my_app'),
          'lib/core/colors.dart');
    });

    test('returns null for a genuine third-party package', () {
      expect(
          resolveProjectImport('package:flutter/material.dart', 'lib/a.dart',
              packageName: 'my_app'),
          isNull);
    });

    test('returns null for dart: URIs', () {
      expect(
          resolveProjectImport('dart:async', 'lib/a.dart',
              packageName: 'my_app'),
          isNull);
    });

    test('resolves a relative import against the importing file', () {
      expect(
          resolveProjectImport('../core/colors.dart',
              'lib/modules/home/page.dart',
              packageName: 'my_app'),
          'lib/modules/core/colors.dart');
    });

    test('returns null for package: URIs when the package name is unknown', () {
      expect(
          resolveProjectImport('package:my_app/a.dart', 'lib/b.dart',
              packageName: null),
          isNull);
    });
  });

  group('Import graph', () {
    late Directory tempDir;

    // Deliberately uses package:<own_name>/... self-imports rather than
    // relative ones — the dominant Flutter convention, and the case the
    // graph was previously blind to.
    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('flutter_project_structure_ig_');
      File('${tempDir.path}/pubspec.yaml')
          .writeAsStringSync('name: graph_app\n');
      Directory('${tempDir.path}/lib/core').createSync(recursive: true);
      Directory('${tempDir.path}/lib/ui').createSync(recursive: true);

      File('${tempDir.path}/lib/main.dart').writeAsStringSync('''
import 'package:graph_app/ui/home.dart';
void main() {}
''');
      File('${tempDir.path}/lib/ui/home.dart').writeAsStringSync('''
import 'package:graph_app/core/colors.dart';
import 'package:flutter/material.dart';
class Home {}
''');
      File('${tempDir.path}/lib/core/colors.dart')
          .writeAsStringSync('class Colors {}');
      // Reachable only via a part directive.
      File('${tempDir.path}/lib/core/cubit.dart').writeAsStringSync('''
import 'package:graph_app/core/colors.dart';
part 'cubit_state.dart';
class Cubit {}
''');
      File('${tempDir.path}/lib/core/cubit_state.dart')
          .writeAsStringSync("part of 'cubit.dart';\nclass CubitState {}");
      // Genuinely orphaned.
      File('${tempDir.path}/lib/core/orphan.dart')
          .writeAsStringSync('class Orphan {}');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    ImportGraph graphOf() {
      final context =
          FlutterProjectStructure(rootDir: '${tempDir.path}/lib').runAnalysis();
      return context!.importGraph!;
    }

    test('captures package:<own_name>/... self-imports as edges', () {
      final graph = graphOf();

      expect(graph.imports['lib/main.dart'], contains('lib/ui/home.dart'));
      expect(graph.imports['lib/ui/home.dart'],
          contains('lib/core/colors.dart'));
    });

    test('excludes third-party packages from the graph', () {
      // home.dart imports package:flutter/material.dart, which is not ours.
      expect(graphOf().imports['lib/ui/home.dart'], hasLength(1));
    });

    test('builds the reverse index', () {
      final graph = graphOf();

      expect(graph.importedBy['lib/core/colors.dart'],
          containsAll(['lib/ui/home.dart', 'lib/core/cubit.dart']));
    });

    test('dependentsOf walks transitively — the blast radius', () {
      // colors <- home <- main
      expect(graphOf().dependentsOf('lib/core/colors.dart'),
          containsAll(['lib/ui/home.dart', 'lib/main.dart']));
    });

    test('dependentsOf honours maxDepth', () {
      final oneHop =
          graphOf().dependentsOf('lib/core/colors.dart', maxDepth: 1);

      expect(oneHop, contains('lib/ui/home.dart'));
      expect(oneHop, isNot(contains('lib/main.dart')),
          reason: 'main.dart is two hops away');
    });

    test('dependenciesOf walks the forward closure', () {
      expect(graphOf().dependenciesOf('lib/main.dart'),
          containsAll(['lib/ui/home.dart', 'lib/core/colors.dart']));
    });

    test('part files count as edges, so they are not false-positive orphans',
        () {
      final graph = graphOf();

      expect(graph.imports['lib/core/cubit.dart'],
          contains('lib/core/cubit_state.dart'));
      expect(graph.unreachableFrom(['lib/core/cubit.dart']),
          isNot(contains('lib/core/cubit_state.dart')));
    });

    test('unreachableFrom finds genuinely orphaned files', () {
      final unreachable = graphOf().unreachableFrom(['lib/main.dart']);

      expect(unreachable, contains('lib/core/orphan.dart'));
      expect(unreachable, isNot(contains('lib/ui/home.dart')));
      expect(unreachable, isNot(contains('lib/core/colors.dart')));
    });

    test('hubs rank the most depended-upon files first', () {
      expect(graphOf().hubs(limit: 1).single.key, 'lib/core/colors.dart');
    });

    test('architecture layer dependencies see package: imports too', () {
      // Regression: layerImports was empty for any project using
      // package:<own_name>/... imports, which is most of them.
      Directory('${tempDir.path}/lib/models').createSync(recursive: true);
      Directory('${tempDir.path}/lib/services').createSync(recursive: true);
      File('${tempDir.path}/lib/models/user.dart')
          .writeAsStringSync('class User {}');
      File('${tempDir.path}/lib/services/api.dart').writeAsStringSync('''
import 'package:graph_app/models/user.dart';
class Api {}
''');

      final context =
          FlutterProjectStructure(rootDir: '${tempDir.path}/lib').runAnalysis();

      expect(context!.architectureAnalyzer!.layerImports['Service'],
          contains('Model'));
    });

    test('graph.json is emitted with nodes, edges and hubs', () {
      final context =
          FlutterProjectStructure(rootDir: '${tempDir.path}/lib').generate()!;
      AiContextGenerator(context)
          .generate(outputDir: '${tempDir.path}/.ai-context');

      final json = jsonDecode(
              File('${tempDir.path}/.ai-context/graph.json').readAsStringSync())
          as Map<String, dynamic>;

      expect(json['nodeCount'], 6);
      expect(json['edgeCount'], greaterThan(0));
      expect((json['imports'] as Map).keys, contains('lib/main.dart'));
      expect((json['hubs'] as List).first['file'], 'lib/core/colors.dart');
      expect(json['unreachable'], contains('lib/core/orphan.dart'));
    });
  });
}
