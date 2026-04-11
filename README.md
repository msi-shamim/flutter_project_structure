# Flutter Project Structure

A Dart package that bridges your codebase and AI agents. Analyze, document, and visualize your Flutter/Dart project structure. Generate AI-friendly context (`CLAUDE.md`, `.ai-context/`) and provide an MCP server for live querying.

## Features

### Core Analysis
- Generate a markdown file detailing your project's structure
- Add path comments to the top of each Dart file
- List imports for each file in collapsible sections
- File statistics (total files, LOC, largest/smallest files)
- TODO/FIXME comment scanning with line numbers
- Package dependency analysis (AST-based)
- Code metrics (classes, methods, comment ratio per file)

### AI Agent Integration (v2.0.0)
- **Project Type Detection** — monorepo, plugin, flutter_app, or dart_package
- **Framework Detection** — GetX, Riverpod, Bloc/Cubit, Provider, Dio, GoRouter, AutoRoute, Freezed, Hive, Drift
- **Architecture Analysis** — layers from directory names, entry points, layer dependency graph
- **Convention Analysis** — file/class naming patterns and suffix adoption rates
- **File Purpose Classification** — widget, model, service, bloc, controller, etc.
- **Aggregated Metrics** — averages, totals, top-5 largest files, files without comments
- **CLAUDE.md Generator** — AI-optimized project context file (<20KB)
- **.ai-context/ Generator** — 6 structured JSON files for programmatic consumption
- **MCP Server** — 5 live-query tools over stdio with `--watch` mode

### Modular Pipeline
- **FileAnalyzer interface** — single-pass file processing, each file read and parsed once
- **AnalysisPipeline** — distributes pre-parsed AST to all registered analyzers
- **ProjectContext** — aggregated results consumed by generators and MCP tools

Before use don't forget to check the [CHANGELOG](CHANGELOG.md) to ensure latest features.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_project_structure: ^2.0.0
```

Then run:

```
dart pub get
```

## CLI Usage

### Analyze (default)

Generate project structure markdown with path comments:

```
dart run flutter_project_structure
dart run flutter_project_structure analyze --root-dir=lib --output=structure.md
```

Running without a subcommand defaults to `analyze` for backward compatibility.

### Generate CLAUDE.md

Generate an AI agent context file (read-only, no source file modification):

```
dart run flutter_project_structure claude-md
dart run flutter_project_structure claude-md --root-dir=src --output=CLAUDE.md
```

### Generate .ai-context/

Generate structured JSON files + CLAUDE.md (read-only):

```
dart run flutter_project_structure ai-context
dart run flutter_project_structure ai-context --root-dir=lib --output-dir=.ai-context
```

Creates 6 JSON files: `architecture.json`, `files.json`, `patterns.json`, `conventions.json`, `metrics.json`, `todos.json`.

### MCP Server

Start an MCP server for live AI agent queries:

```
dart run flutter_project_structure mcp-server
dart run flutter_project_structure mcp-server --watch
```

With `--watch`, the server re-analyzes when `.dart` files change (2-second debounce).

**5 MCP tools exposed:**
- `get_architecture` — project type, layers, dependency graph, entry points
- `get_file_purpose(path)` — purpose and metrics for a specific file
- `get_dependencies(package?)` — package dependencies, optionally filtered
- `get_conventions` — naming patterns and suffix adoption
- `get_todos(severity?)` — TODO/FIXME items, optionally filtered by severity

**Claude Code configuration:**
```json
{
  "mcpServers": {
    "flutter-project-structure": {
      "command": "dart",
      "args": ["run", "flutter_project_structure", "mcp-server", "--watch"]
    }
  }
}
```

### Options

**Analyze command flags:**
- `--root-dir` or `-r`: Root directory to analyze (default: 'lib')
- `--output` or `-o`: Output file name (default: 'project_structure.md')
- `--file-stats` or `-f`: Include file statistics (default: true)
- `--todo-comments` or `-t`: Include TODO/FIXME comments (default: true)
- `--dependency-analysis` or `-d`: Include dependency analysis (default: true)
- `--code-metrics` or `-m`: Include code metrics (default: true)
- `--project-type`: Detect project type (default: true)
- `--framework-detection`: Detect frameworks (default: true)
- `--architecture`: Analyze architectural layers (default: true)
- `--conventions`: Analyze naming conventions (default: true)
- `--file-purpose`: Classify file purposes (default: true)
- `--metrics-aggregation`: Compute aggregated metrics (default: true)

Use `--no-<flag>` to disable any feature (e.g., `--no-framework-detection`).

## Programmatic Usage

### Basic (v1.x compatible)

```dart
import 'package:flutter_project_structure/flutter_project_structure.dart';

void main() {
  final structure = FlutterProjectStructure(rootDir: 'lib', outputFile: 'project_structure.md');
  structure.generate(); // Writes markdown + adds path comments to source files
}
```

### Read-Only Analysis (v2.0.0)

```dart
import 'package:flutter_project_structure/flutter_project_structure.dart';

void main() {
  final structure = FlutterProjectStructure(rootDir: 'lib');
  final context = structure.runAnalysis(); // Read-only, no file modification
  if (context == null) return;

  print('Project type: ${context.projectTypeDetector?.projectType}');
  print('Total files: ${context.fileStatistics.totalFiles}');
  print('Frameworks: ${context.frameworkDetector?.detectedFrameworks.keys}');
}
```

### Generate AI Context

```dart
import 'package:flutter_project_structure/flutter_project_structure.dart';

void main() {
  final structure = FlutterProjectStructure(rootDir: 'lib');
  final context = structure.runAnalysis();
  if (context == null) return;

  // Generate CLAUDE.md
  ClaudeMdGenerator(context).generate(outputPath: 'CLAUDE.md');

  // Generate .ai-context/ JSON files
  AiContextGenerator(context).generate(outputDir: '.ai-context');
}
```

## Architecture

```
AnalysisPipeline (reads & parses each file once)
  ├── FileStatistics        — file/line counts, largest/smallest files
  ├── TodoComments          — TODO/FIXME scanning
  ├── DependencyAnalysis    — package import mapping (AST-based)
  ├── CodeMetrics           — classes, methods, comment ratio (AST-based)
  ├── FrameworkDetector     — framework/library detection (pubspec + AST)
  ├── ArchitectureAnalyzer  — layers, entry points, dependency graph
  ├── ConventionAnalyzer    — file/class naming patterns
  └── FilePurposeAnalyzer   — file role classification

Output Generators
  ├── Markdown              — project_structure.md (analyze command)
  ├── ClaudeMdGenerator     — CLAUDE.md for AI agents
  ├── AiContextGenerator    — .ai-context/ JSON files
  └── McpProjectServer      — MCP server with 5 tools
```

All analyzers implement the `FileAnalyzer` interface and receive pre-parsed data from the pipeline. You can build custom analyzers:

```dart
import 'dart:io';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_project_structure/flutter_project_structure.dart';

class MyCustomAnalyzer implements FileAnalyzer {
  @override
  void analyzeFile(File file, String content, CompilationUnit? compilationUnit) {
    // Your analysis logic here
  }
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
