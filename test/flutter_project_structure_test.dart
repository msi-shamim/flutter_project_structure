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
      testFile.writeAsStringSync('void main() {}');
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
      print('File content after processing:');
      print(content);

      final expectedPath = path.relative(testFile.path,
          from: path.dirname(path.dirname(testFile.path)));
      final expectedComment = '// Path: $expectedPath';
      print('Expected comment: $expectedComment');

      expect(content.startsWith(expectedComment), isTrue,
          reason: 'File content does not start with expected comment');
    });
  });
}
