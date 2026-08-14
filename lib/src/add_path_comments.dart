// lib/src/add_path_comments.dart
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Adds a path comment to the top of a Dart file.
///
/// [relativePath] must be the canonical project-root-relative path (see
/// `relativePathFor`), e.g. `lib/src/widgets/foo_widget.dart`, so the comment
/// matches the paths reported everywhere else in the generated output.
void addPathComment(File file, String relativePath) {
  final content = file.readAsStringSync();
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

  print('Processed: ${file.path}');
  print('Added comment: $comment');
}

/// Lists imports for a given Dart file and adds them to the project structure.
void listImports(File file, StringBuffer projectStructure, int level) {
  final content = file.readAsStringSync();
  final result = parseString(content: content);
  final unit = result.unit;

  final imports = <String>[];

  for (final directive in unit.directives) {
    if (directive is ImportDirective) {
      imports.add(directive.uri.stringValue!);
    }
  }

  imports.sort();

  final indent = '  ' * level;
  if (imports.isNotEmpty) {
    projectStructure.writeln('$indent  <details>');
    projectStructure.writeln('$indent    <summary>Imports</summary>\n');
    for (final import in imports) {
      projectStructure.writeln('$indent    - `$import`');
    }
    projectStructure.writeln('$indent  </details>\n');
  }
}
