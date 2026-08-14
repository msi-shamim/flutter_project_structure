# Flutter Project Structure

[![pub package](https://img.shields.io/pub/v/flutter_project_structure.svg)](https://pub.dev/packages/flutter_project_structure)
[![pub points](https://img.shields.io/pub/points/flutter_project_structure)](https://pub.dev/packages/flutter_project_structure/score)
[![likes](https://img.shields.io/pub/likes/flutter_project_structure)](https://pub.dev/packages/flutter_project_structure)
[![popularity](https://img.shields.io/pub/popularity/flutter_project_structure)](https://pub.dev/packages/flutter_project_structure)
[![license](https://img.shields.io/github/license/msi-shamim/flutter_project_structure)](https://github.com/msi-shamim/flutter_project_structure/blob/main/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/msi-shamim/flutter_project_structure?style=social)](https://github.com/msi-shamim/flutter_project_structure)

**Save 90% of AI tokens.** Run one command and every AI agent — Claude Code, Cursor, Copilot — instantly understands your project. No more wasting tokens on exploration. Handle **9x more projects** with the same AI subscription.

A Dart package that makes your Flutter/Dart codebase AI-ready. Analyze, document, and visualize your project structure. Generate AI-friendly context files that eliminate the expensive "let me explore your codebase" phase that costs you thousands of tokens every session.

## Why? (The Token Problem)

AI agents struggle with large Flutter projects. Every new session, the agent spends **50,000-80,000 tokens** just figuring out your project before writing a single line of useful code:

- Reading dozens of files to understand the directory structure
- Exploring imports to detect which frameworks you use
- Asking you about architecture patterns and conventions
- Repeating all of this in the next session — and the next one

If you're using premium AI agents like **Claude Code with Opus or Sonnet**, those orientation tokens add up fast. That's real money burned on exploration instead of actual development.

**flutter_project_structure** fixes this. One command and your project gets:

- **Path comments** in every Dart file (`// Path: lib/src/...`) — AI knows where every file sits, zero extra tokens
- **project_structure.md** — comprehensive directory tree with full analysis
- **CLAUDE.md** — compact AI-optimized context (<20KB) that agents read automatically
- **.ai-context/** — 6 structured JSON files for programmatic querying
- **MCP server** — 6 live-query tools for real-time project understanding

Every command always produces path comments + `project_structure.md` as a baseline. The specific command just adds its own output on top. **One command = full AI-readiness.**

## How It Saves 90% of AI Tokens (Real Math)

Here's a real-world breakdown using a **384-file Flutter production app** (47,526 lines of Dart code, BLoC + Dio + GoRouter + Freezed + Hive):

### Without flutter_project_structure

Every AI session starts with the agent exploring your project from scratch:

| Task | Tool Calls | Tokens Used |
|------|:----------:|:-----------:|
| List directories to understand structure | ~8 calls | ~4,000 |
| Read key files to detect frameworks | ~25 file reads | ~25,000 |
| Explore imports to map dependencies | ~15 file reads | ~12,000 |
| Figure out architecture (layers, patterns) | ~10 file reads | ~8,000 |
| Ask developer about conventions, entry points | ~5 back-and-forth | ~3,000 |
| Re-read files because context got lost | ~10 file reads | ~8,000 |
| **Total orientation cost per session** | **~73 calls** | **~60,000 tokens** |

And this repeats **every single session**. 5 sessions a day = **300,000 tokens/day** just on orientation.

### With flutter_project_structure

Run once: `dart run flutter_project_structure ai-context`

| Task | Tool Calls | Tokens Used |
|------|:----------:|:-----------:|
| AI reads CLAUDE.md (auto-loaded, 4.8KB) | 0 (automatic) | ~1,500 |
| Path comments already in every file | 0 (embedded) | 0 |
| Occasional MCP query for specific detail | ~2 calls | ~1,000 |
| **Total orientation cost per session** | **~2 calls** | **~2,500 tokens** |

### The Math

```
Without:  60,000 tokens/session  x  5 sessions/day  =  300,000 tokens/day
With:      2,500 tokens/session  x  5 sessions/day  =   12,500 tokens/day

Savings:  287,500 tokens/day  =  95.8% reduction
```

**Conservatively: 90% token savings per project.**

### What This Means for Your Wallet

If you're on a **Claude Code subscription** using Opus or Sonnet models:

- **Without this package:** Your token budget covers ~1 project's worth of AI-assisted development
- **With this package:** The same budget covers **~9 projects** (90% less tokens per project = 9x more capacity)

The package runs once (or on each code change with `--watch`), costs zero AI tokens, and the generated context files keep paying off every session, every day, for the life of the project.

> **One `dart pub add` today saves thousands of dollars in AI tokens over the project lifecycle.**

## Features

### Core Analysis
- Directory tree visualization in markdown
- Path comments added to the top of each Dart file for AI navigation
- File statistics (total files, lines of code, largest/smallest files)
- TODO/FIXME comment scanning with line numbers
- Package dependency analysis (AST-based import tracking)
- Code metrics per file (classes, methods, comment ratio)

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
