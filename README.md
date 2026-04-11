# Flutter Project Structure

A Dart package that makes your codebase AI-ready. Run one command and every AI agent — Claude Code, Cursor, Copilot — instantly understands your project: its architecture, conventions, frameworks, and file purposes.

## Why?

AI agents struggle with large Flutter projects. They read a few files but miss the big picture — architecture, naming conventions, framework choices, entry points. You end up repeating context every session.

**flutter_project_structure** fixes this. One command and your project gets:

- **Path comments** in every Dart file (`// Path: lib/src/...`) — AI knows where every file sits
- **project_structure.md** — comprehensive directory tree with full analysis
- **CLAUDE.md** — compact AI-optimized context (<20KB) that agents read automatically
- **.ai-context/** — 6 structured JSON files for programmatic querying
- **MCP server** — 6 live-query tools for real-time project understanding

Every command always produces path comments + `project_structure.md` as a baseline. The specific command just adds its own output on top. One command = full AI-readiness.

## Features

### Core Analysis
- Directory tree visualization in markdown
- Path comments added to the top of each Dart file for AI navigation
- File statistics (total files, lines of code, largest/smallest files)
- TODO/FIXME comment scanning with line numbers
- Package dependency analysis (AST-based import tracking)
- Code metrics per file (classes, methods, comment ratio)

### Smart Detection (v2.0.0)
- **Project Type** — monorepo, plugin, flutter_app, or dart_package
- **10 Frameworks** — GetX, Riverpod, Bloc/Cubit, Provider, Dio, GoRouter, AutoRoute, Freezed, Hive, Drift (detected via pubspec + imports + AST superclass matching)
- **Architecture Layers** — maps directories to layers (models, services, controllers, widgets, blocs, etc.) with dependency graph
- **Entry Points** — detects `main.dart`, `app.dart`, and environment variants like `main_development.dart`, `main_staging.dart`, `main_production.dart`
- **Naming Conventions** — file suffix patterns (`_model`, `_service`, `_bloc`) and class suffix patterns (`Model`, `Service`, `Bloc`)
- **File Purpose Classification** — every file gets a role: widget, model, service, bloc, test, generated, utility, etc.
- **Aggregated Metrics** — averages, totals, top-5 largest files, files without comments

### AI Output Generators
- **CLAUDE.md** — AI-optimized project summary (<20KB) with overview, architecture, conventions, dependencies, and code health
- **.ai-context/** — 6 JSON files: `architecture.json`, `files.json`, `patterns.json`, `conventions.json`, `metrics.json`, `todos.json`
- **MCP Server** — 6 live-query tools over stdio JSON-RPC with optional `--watch` mode

### Single-Pass Architecture
- **FileAnalyzer interface** — each file is read and parsed once, then distributed to all analyzers
- **AnalysisPipeline** — orchestrates single-pass processing (3x faster than per-analyzer scanning)
- **ProjectContext** — all analysis results in one data class, consumed by generators and MCP tools

## Installation

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_project_structure: ^2.0.0
```

Then run:

```
dart pub get
```

## CLI Usage

### Quick Start

```bash
# Analyze your project — generates project_structure.md with path comments
dart run flutter_project_structure

# Full AI setup — project_structure.md + CLAUDE.md + .ai-context/ JSON files
dart run flutter_project_structure ai-context

# Start MCP server for live AI agent queries
dart run flutter_project_structure mcp-server --watch
```

### Commands

Every command produces path comments + `project_structure.md` as baseline, then adds its own specific output.

#### `analyze` (default)

The core command. Generates `project_structure.md` with directory tree and all analysis sections. Adds `// Path:` comments to every Dart file.

```bash
dart run flutter_project_structure
dart run flutter_project_structure analyze --root-dir=lib --output=structure.md
```

Running without a subcommand defaults to `analyze` for backward compatibility.

#### `claude-md`

Generates `CLAUDE.md` — a compact, AI-optimized project context file (<20KB). AI agents like Claude Code read this automatically at the start of every session.

```bash
dart run flutter_project_structure claude-md
dart run flutter_project_structure claude-md --output=AI_CONTEXT.md
```

Also produces: path comments + `project_structure.md`.

#### `ai-context`

The most comprehensive command. Generates everything: `project_structure.md`, `CLAUDE.md`, and 6 structured JSON files in `.ai-context/`.

```bash
dart run flutter_project_structure ai-context
dart run flutter_project_structure ai-context --output-dir=.ai-context
```

JSON files created:
- `architecture.json` — project type, layers, dependency graph, entry points
- `files.json` — every file with purpose, LOC, classes, methods, comment ratio
- `patterns.json` — detected frameworks with file evidence
- `conventions.json` — naming suffix counts and file purpose distribution
- `metrics.json` — aggregated code health metrics
- `todos.json` — structured TODO/FIXME index

Also produces: path comments + `project_structure.md` + `CLAUDE.md`.

#### `mcp-server`

Starts an MCP server for real-time AI agent queries. The server analyzes your project on startup, and optionally watches for file changes.

```bash
dart run flutter_project_structure mcp-server
dart run flutter_project_structure mcp-server --watch
```

With `--watch`, the server re-analyzes when `.dart` files change (2-second debounce). Also produces path comments + `project_structure.md` at startup.

**6 MCP tools exposed:**

| Tool | Description |
|------|-------------|
| `get_architecture` | Project type, layers, dependency graph, entry points |
| `get_file_purpose(path)` | Purpose and metrics for a specific file |
| `get_dependencies(package?)` | Package dependencies, optionally filtered |
| `get_conventions` | Naming patterns and suffix adoption rates |
| `get_todos(severity?)` | TODO/FIXME items, optionally filtered |
| `get_project_structure(section?)` | Full project structure markdown — returns summary by default, or a specific section (tree, frameworks, architecture, etc.) |

**Configure in Claude Code:**

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

**Analyze command flags** (all enabled by default):

| Flag | Short | Description |
|------|-------|-------------|
| `--root-dir` | `-r` | Root directory to analyze (default: `lib`) |
| `--output` | `-o` | Output file name (default: `project_structure.md`) |
| `--file-stats` | `-f` | File/line counting |
| `--todo-comments` | `-t` | TODO/FIXME scanning |
| `--dependency-analysis` | `-d` | Package import tracking |
| `--code-metrics` | `-m` | Classes, methods, comment ratio |
| `--project-type` | | Project type detection |
| `--framework-detection` | | Framework/library detection |
| `--architecture` | | Layer and dependency analysis |
| `--conventions` | | Naming convention analysis |
| `--file-purpose` | | File role classification |
| `--metrics-aggregation` | | Aggregated health metrics |

Disable any feature with `--no-<flag>` (e.g., `--no-framework-detection`).

## Programmatic Usage

### Full Analysis with Path Comments

```dart
import 'package:flutter_project_structure/flutter_project_structure.dart';

void main() {
  final structure = FlutterProjectStructure(
    rootDir: 'lib',
    outputFile: 'project_structure.md',
  );

  // generate() injects path comments, writes project_structure.md,
  // and returns a ProjectContext for further use
  final context = structure.generate();
  if (context == null) return;

  print('Project type: ${context.projectTypeDetector?.projectType}');
  print('Total files: ${context.fileStatistics.totalFiles}');
  print('Frameworks: ${context.frameworkDetector?.detectedFrameworks.keys}');

  // Use the context with generators
  ClaudeMdGenerator(context).generate(outputPath: 'CLAUDE.md');
  AiContextGenerator(context).generate(outputDir: '.ai-context');
}
```

### Read-Only Analysis (no file modification)

```dart
final structure = FlutterProjectStructure(rootDir: 'lib');
final context = structure.runAnalysis();
// Or get the markdown string without writing to disk:
final markdown = structure.generateMarkdown();
```

## Architecture

```
AnalysisPipeline (reads & parses each file once)
  |-- FileStatistics        -- file/line counts, largest/smallest files
  |-- TodoComments          -- TODO/FIXME scanning
  |-- DependencyAnalysis    -- package import mapping (AST-based)
  |-- CodeMetrics           -- classes, methods, comment ratio (AST-based)
  |-- FrameworkDetector     -- framework detection (pubspec + imports + AST)
  |-- ArchitectureAnalyzer  -- layers, entry points, dependency graph
  |-- ConventionAnalyzer    -- file/class naming patterns
  |-- FilePurposeAnalyzer   -- file role classification

Every command produces (baseline):
  |-- Path comments         -- // Path: lib/src/... in every Dart file
  |-- project_structure.md  -- comprehensive directory tree + all analysis

Output Generators (added on top):
  |-- ClaudeMdGenerator     -- CLAUDE.md for AI agents (<20KB)
  |-- AiContextGenerator    -- .ai-context/ (6 JSON files)
  |-- McpProjectServer      -- MCP server with 6 live-query tools
```

All analyzers implement the `FileAnalyzer` interface. You can build custom analyzers:

```dart
import 'dart:io';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_project_structure/flutter_project_structure.dart';

class MyCustomAnalyzer implements FileAnalyzer {
  @override
  void analyzeFile(File file, String content, CompilationUnit? compilationUnit) {
    // Your analysis logic here — receives pre-parsed AST
  }
}
```

## Example

Check the `example` folder for a complete usage example:

```
dart run example/main.dart
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support the Project

If you find this package helpful, consider supporting it by Liking it on [pub.dev](https://pub.dev/packages/flutter_project_structure).

## Connect with Me

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

Thank you for checking out Flutter Project Structure! I hope it proves useful in your development workflow. Happy Coding!
