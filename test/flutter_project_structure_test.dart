// test/flutter_project_structure_test.dart
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
}
