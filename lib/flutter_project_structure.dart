library flutter_project_structure;

import 'dart:io';

import 'package:path/path.dart' as path;

import 'src/add_path_comments.dart';

class FlutterProjectStructure {
  final String rootDir;
  final String outputFile;

  FlutterProjectStructure({
    this.rootDir = 'lib',
    this.outputFile = 'project_structure.md',
  });

  void generate() {
    final libDir = Directory(rootDir);
    if (!libDir.existsSync()) {
      print("Error: '$rootDir' directory not found.");
      return;
    }

    final projectStructure = StringBuffer();
    projectStructure.writeln("# Project Structure\n");

    _processDirectory(libDir, projectStructure, 0);

    File(outputFile).writeAsStringSync(projectStructure.toString());
    print("Finished processing files.");
    print("Project structure written to $outputFile");
  }

  void _processDirectory(
      Directory dir, StringBuffer projectStructure, int level) {
    final entities = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));

    for (var entity in entities) {
      final relativePath = path.relative(entity.path, from: rootDir);
      final indent = '  ' * level;

      if (entity is File && entity.path.endsWith('.dart')) {
        print("Processing file: ${entity.path}");
        addPathComment(entity);
        projectStructure.writeln('$indent- 📄 `$relativePath`');
        listImports(entity, projectStructure, level + 1);
      } else if (entity is Directory) {
        projectStructure
            .writeln('$indent- 📁 **${path.basename(entity.path)}**');
        _processDirectory(entity, projectStructure, level + 1);
      }
    }
  }
}
