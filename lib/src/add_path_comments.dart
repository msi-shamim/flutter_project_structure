import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;

void addPathComment(File file) {
  final content = file.readAsStringSync();
  final relativePath =
      path.relative(file.path, from: path.dirname(path.dirname(file.path)));
  final comment = '// Path: $relativePath\n';

  if (content.startsWith('//')) {
    final lines = content.split('\n');
    if (lines[0].startsWith('// Path:')) {
      lines[0] = comment.trim();
      file.writeAsStringSync(lines.join('\n'));
    } else {
      file.writeAsStringSync(comment + content);
    }
  } else {
    file.writeAsStringSync(comment + content);
  }

  print("Processed: ${file.path}");
  print("Added comment: $comment");
}

void listImports(File file, StringBuffer projectStructure, int level) {
  final content = file.readAsStringSync();
  final result = parseString(content: content);
  final unit = result.unit;

  final imports = <String>[];

  for (var directive in unit.directives) {
    if (directive is ImportDirective) {
      imports.add(directive.uri.stringValue!);
    }
  }

  imports.sort();

  final indent = '  ' * level;
  if (imports.isNotEmpty) {
    projectStructure.writeln('$indent  <details>');
    projectStructure.writeln('$indent    <summary>Imports</summary>\n');
    for (var import in imports) {
      projectStructure.writeln('$indent    - `$import`');
    }
    projectStructure.writeln('$indent  </details>\n');
  }
}
