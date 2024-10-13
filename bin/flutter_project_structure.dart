import 'package:args/args.dart';
import 'package:flutter_project_structure/flutter_project_structure.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('root-dir',
        abbr: 'r', defaultsTo: 'lib', help: 'The root directory to analyze')
    ..addOption('output',
        abbr: 'o',
        defaultsTo: 'project_structure.md',
        help: 'The output file name')
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Show this help message');

  try {
    final results = parser.parse(arguments);

    if (results['help']) {
      print('Usage: dart run flutter_project_structure [options]');
      print(parser.usage);
      return;
    }

    final rootDir = results['root-dir'];
    final outputFile = results['output'];

    final projectStructure =
        FlutterProjectStructure(rootDir: rootDir, outputFile: outputFile);
    projectStructure.generate();

    print('Project structure generated successfully.');
    print('Output file: $outputFile');
  } catch (e) {
    print('Error: $e');
    print('Usage: dart run flutter_project_structure [options]');
    print(parser.usage);
  }
}
