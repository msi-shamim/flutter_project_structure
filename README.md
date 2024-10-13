# Flutter Project Structure

A Dart package to showcase the current structure of your Flutter project and add path comments at the top of each Dart file.

## Features

- Generate a markdown file detailing your project's structure
- Add path comments to the top of each Dart file in your project
- List imports for each file in the project structure
- Support for custom root directories and output file names
- Command-line interface for easy project structure generation
- File Statistics to count of total files, directories, and Dart files.
- TODO and FIXME Comments to scan files for TODO and FIXME comments and list them in a separate collapsible section.
- Dependency Analysis to list all external package dependencies used in the project.
- Code Metrics to calculate and display simple code metrics like lines of code, comment percentage, etc. 

Before use don't forget to check the [CHANGELOG](CHANGELOG.md) to ensure latest features.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_project_structure: ^1.0.2
```

Then run:

```
flutter pub get
```

## Usage

You can use this package as a command-line tool to generate your project structure within a press of the Enter button.

### Basic Usage

To generate the project structure with default settings:

```
dart run flutter_project_structure
```

This will analyze the `lib` directory and generate a `project_structure.md` file in your project root.

### Custom Usage

You can specify custom root directories and output file names:

```
dart run flutter_project_structure --root-dir=src --output=custom_structure.md --no-file-stats --no-todo-comments
```

This will analyze the `src` directory and output the structure to `custom_structure.md`.

### Options

- `--root-dir` or `-r`: Specify the root directory to analyze (default: 'lib')
- `--output` or `-o`: Specify the output file name (default: 'project_structure.md')
- `--file-stats` or `-f`: Include file statistics (default: true)
- `--todo-comments` or `-t`: Include TODO and FIXME comments (default: true)
- `--dependency-analysis` or `-d`: Include dependency analysis (default: true)
- `--code-metrics` or `-m`: Include code metrics (default: true)
- `--help` or `-h`: Show this help message

You can use `--no-file-stats`, `--no-todo-comments`, `--no-dependency-analysis`, or `--no-code-metrics` to exclude specific features from the analysis.

## Programmatic Usage

You can also use this package programmatically in your Dart code:

```dart
import 'package:flutter_project_structure/flutter_project_structure.dart';

void main() {
  final projectStructure = FlutterProjectStructure(rootDir: 'lib', outputFile: 'project_structure.md');
  projectStructure.generate();
}
```

## Example

Check the `example` folder for a complete example of how to use this package programmatically.

To run the example:

```
dart run example/main.dart
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support the Project

If you find this package helpful, consider supporting it by Liking it in pub.dev

## Connect with Me

Feel free to reach out for questions, suggestions, or just to say hi!

- LinkedIn: [LinkedIn Profile](https://www.linkedin.com/in/msishamim)
- GitHub: [GitHub Profile](https://github.com/msi-shamim)

## Hire Me or Contact My Organization

For freelance work or larger projects:

- Upwork Individual Profile: [Individual Profile](https://upwork.com/freelancers/msifullstack)
- Upwork Agency: [Agency Profile](https://www.upwork.com/agencies/incrementsinc/)

For large scale developments or to discuss potential collaborations, please reach out via email at: im.msishamim@gmail.com

## Success Stories

I'm proud to have contributed to the success of various projects. Here's one of my highlights:

### Abwaab.com

Abwaab is one of the top EdTech platforms in the MENA region. I played a crucial role in developing robust and scalable solutions that helped Abwaab achieve its mission of making high-quality education accessible to millions of students.

[Visit Abwaab](https://www.abwaab.com)

## My Organization

### Increments Inc. 

Our software automates restaurants, optimizes energy, revolutionizes finance, improves healthcare, innovates education, streamlines garments, and drives paperless solutions.
Increments Inc. is Bangladesh's #1 mobile app development agency.

[Visit Increments Inc.](https://incrementsinc.com)

---

Thank you for checking out Flutter Project Structure! I hope it proves useful in your development workflow. Happy Coding! ☕️ 
