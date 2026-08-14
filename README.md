# Flutter Project Structure

[![pub package](https://img.shields.io/pub/v/flutter_project_structure.svg)](https://pub.dev/packages/flutter_project_structure)
[![pub points](https://img.shields.io/pub/points/flutter_project_structure)](https://pub.dev/packages/flutter_project_structure/score)
[![likes](https://img.shields.io/pub/likes/flutter_project_structure)](https://pub.dev/packages/flutter_project_structure)
[![popularity](https://img.shields.io/pub/popularity/flutter_project_structure)](https://pub.dev/packages/flutter_project_structure)
[![license](https://img.shields.io/github/license/msi-shamim/flutter_project_structure)](https://github.com/msi-shamim/flutter_project_structure/blob/main/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/msi-shamim/flutter_project_structure?style=social)](https://github.com/msi-shamim/flutter_project_structure)

**90% less context to understand your codebase.** One command gives every AI agent — Claude Code, Cursor, Copilot — a complete structural picture of your project: what every file offers, how they connect, and what breaks if you change one. The numbers below are measured on a real app, not estimated.

A Dart package that makes your Flutter/Dart codebase AI-ready. Analyze, document, and visualize your project structure, and generate context files that replace the expensive "let me go read your codebase" phase.

## Why? (The Context Problem)

Before an agent writes anything useful in your repo, it has to answer three questions:

1. **What is this project?** — stack, architecture, conventions, entry points
2. **Which files matter for this task?** — and what else depends on them
3. **What do those files offer?** — the classes and methods it needs to call

Answering those by reading source is expensive, and it starts over every session. `breeze_buy_app`, a real 170-file Flutter app, is **670 KB of Dart — roughly 171,000 tokens** to read end to end. No agent reads all of it, so it opens files semi-blindly until it has enough context, then pays again tomorrow.

## What you get instead

Run once: `dart run flutter_project_structure ai-context`

| Artifact | Answers | Measured on `breeze_buy_app` |
|---|---|---|
| `CLAUDE.md` | What is this project? | **2.6 KB** (~670 tokens), auto-loaded by Claude Code |
| `.ai-context/graph.json` | Which files matter, what breaks if I change one | 777 edges across 170 files |
| `.ai-context/skeletons.json` | What does each file offer | **63 KB vs 670 KB of source — 90.6% smaller** |

The complete structural picture of that app is **~17,000 tokens** instead of ~171,000 to read the source. That is where the 90% comes from, and you can reproduce it by running the tool on your own project — the compression ratio is reported in `skeletons.json`.

### What a skeleton looks like

```
lib/core/utils/http_base_interceptor.dart
  class BaseInterceptor extends Interceptor  // base [Interceptor] for [Dio]...
    @override void onRequest(RequestOptions options, RequestInterceptorHandler handler)
    @override void onResponse(Response response, ResponseInterceptorHandler handler)
    @override Future onError(DioException err, ErrorInterceptorHandler handler)
  class RefreshToken
    final String access;
    RefreshToken({required this.access})
```

Enough to *call* that file correctly without opening it. Read the file itself only when you need to *change* it.

### And the graph tells you what a change costs

```
get_file_graph(path: "lib/config/colors.dart")
  importedBy   : 108 files
  blastRadius  : 134 of 170 files
```

## What this does and does not do

The distinction matters, so here it is plainly.

**It does:** give an agent complete structural and interface knowledge of your whole project — every file, every public API, every dependency edge — for about a tenth of what reading the source costs. It stops the agent guessing which files to open, and stops it re-deriving your architecture every session.

**It does not:** tell an agent what your code *does*. Behaviour lives in method bodies, and skeletons drop bodies by definition. This is strongest for services, models, blocs and repositories, where the interface really is most of the meaning. It is weakest for Flutter widgets, where the meaning lives in the `build()` body and the skeleton is closer to a table of contents.

Nor does it shrink a whole session. Writing code, running tests and iterating are untouched — and on a real task those usually cost more than context does. What this package removes is the part you were paying for repeatedly and getting nothing new from.


## Features

### Core Analysis
- Directory tree visualization in markdown
- Path comments (`// Path: lib/src/...`) added to the top of each Dart file — most useful for RAG-based tools whose indexing chunks files and loses the path; agentic tools like Claude Code already receive a path with every result
- File statistics (total files, lines of code, largest/smallest files)
- TODO/FIXME comment scanning with line numbers
- Package dependency analysis (AST-based import tracking)
- Code metrics per file (classes, methods, comment ratio)

### Skeletons (v3.0.0)
- **API skeletons** — every declaration with its body stripped, **90.6% smaller than the source** on a real 170-file app
- **Doc summaries** — the author's own one-line description of each declaration, kept alongside the signature
- Lets an agent hold the shape of a whole project in context and read full bodies only for files it actually edits
- Strongest for services, models, blocs and repositories; for Flutter widgets the meaning lives in the `build()` body, so the skeleton is a table of contents rather than a summary

### Import Graph (v3.0.0)
- **File dependency graph** — nodes are files, edges are `import`, `export` and `part` directives resolved inside the project (including `package:<own_name>/...` self-imports)
- **Blast radius** — the transitive set of files a change to any file could affect, so you know what to check before editing
- **Forward closure** — everything a file needs to work
- **Dead-code candidates** — files unreachable from any entry point
- **Hubs** — the most depended-upon files, i.e. the riskiest to change

### Smart Detection (v3.0.0)
- **Project Type** — monorepo, plugin, flutter_app, or dart_package
- **10 Frameworks** — GetX, Riverpod, Bloc/Cubit, Provider, Dio, GoRouter, AutoRoute, Freezed, Hive, Drift (detected via pubspec + imports + AST superclass matching)
- **Architecture Layers** — maps directories to layers (models, services, controllers, widgets, blocs, etc.) with dependency graph
- **Entry Points** — detects `main.dart`, `app.dart`, and environment variants like `main_development.dart`, `main_staging.dart`, `main_production.dart`
- **Naming Conventions** — file suffix patterns (`_model`, `_service`, `_bloc`) and class suffix patterns (`Model`, `Service`, `Bloc`)
- **File Purpose Classification** — every file gets a role: widget, model, service, bloc, test, generated, utility, etc.
- **Aggregated Metrics** — averages, totals, top-5 largest files, files without comments

### AI Output Generators
- **CLAUDE.md** — AI-optimized project summary (<20KB) with overview, architecture, conventions, dependencies, and code health
- **.ai-context/** — 8 JSON files: `architecture.json`, `files.json`, `patterns.json`, `conventions.json`, `metrics.json`, `todos.json`, `graph.json`, `skeletons.json`
- **MCP Server** — 8 live-query tools over stdio JSON-RPC with optional `--watch` mode

### Single-Pass Architecture
- **FileAnalyzer interface** — each file is read and parsed once, then distributed to all analyzers
- **AnalysisPipeline** — orchestrates single-pass processing (3x faster than per-analyzer scanning)
- **ProjectContext** — all analysis results in one data class, consumed by generators and MCP tools

## Installation

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_project_structure: ^3.0.0
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

The most comprehensive command. Generates everything: `project_structure.md`, `CLAUDE.md`, and 8 structured JSON files in `.ai-context/`.

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

**8 MCP tools exposed:**

| Tool | Description |
|------|-------------|
| `get_architecture` | Project type, layers, dependency graph, entry points |
| `get_file_purpose(path)` | Purpose and metrics for a specific file |
| `get_dependencies(package?)` | Package dependencies, optionally filtered |
| `get_conventions` | Naming patterns and suffix adoption rates |
| `get_todos(severity?)` | TODO/FIXME items, optionally filtered |
| `get_file_skeleton(path?, paths?)` | A file's declarations without their bodies — ~10% the size of reading it. Use to learn how to *call* a file; read the file to *change* it |
| `get_file_graph(path?, depth?)` | File dependency graph. No args: size, most depended-upon files, unreachable files. With `path`: what it imports, what imports it, and its blast radius |
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
| `--output` | `-o` | Output file path (default: `project_structure.md` in the project root) |
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
  // Omit outputFile to write project_structure.md to the project root
  // (next to pubspec.yaml). Pass one to choose your own path.
  final structure = FlutterProjectStructure(rootDir: 'lib');

  // generate() injects path comments, writes project_structure.md,
  // and returns a ProjectContext for further use
  final context = structure.generate();
  if (context == null) return;

  print('Written to: ${structure.outputFilePath}');
  print('Project type: ${context.projectTypeDetector?.projectType}');
  print('Total files: ${context.fileStatistics.totalFiles}');
  print('Frameworks: ${context.frameworkDetector?.detectedFrameworks.keys}');

  // Generators default to the project root too, and return the path written
  print(ClaudeMdGenerator(context).generate());
  print(AiContextGenerator(context).generate());
}
```

Output locations follow one rule: **omit the flag and output lands in the
project root** (beside `pubspec.yaml`), so it stays with the project you
analyzed rather than wherever you happened to run the command from. Pass an
explicit path and it is used as given, resolved against the current directory
like any other CLI tool.

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
  |-- AiContextGenerator    -- .ai-context/ (8 JSON files)
  |-- McpProjectServer      -- MCP server with 8 live-query tools
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
