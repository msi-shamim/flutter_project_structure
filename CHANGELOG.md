## 2.0.0 — AI Agent Integration

The biggest update yet. One command now makes your entire Flutter project AI-ready — path comments in every file, comprehensive analysis, and multiple output formats for AI agents.

### What's New

**Every command is now a full setup.** Whether you run `analyze`, `claude-md`, `ai-context`, or `mcp-server`, you always get:
- Path comments (`// Path: lib/src/...`) injected into every Dart file
- `project_structure.md` generated with directory tree + full analysis

The specific command then adds its own output on top (CLAUDE.md, JSON files, MCP server).

### Single-Pass Architecture
- **FileAnalyzer interface** — all analyzers share a single file read and AST parse (3x faster)
- **AnalysisPipeline** — reads each file once, distributes pre-parsed data to all analyzers
- **ProjectContext** — unified results container used by all generators
- **`generate()` returns `ProjectContext?`** — one call gives you path comments + markdown + analysis data for generators
- **`generateMarkdown()`** — read-only method that returns the full markdown string without writing files
- **`runAnalysis()`** — read-only analysis returning ProjectContext without any file modification

### 6 New Analyzers
- **ProjectTypeDetector** — detects monorepo, plugin, flutter_app, or dart_package
- **FrameworkDetector** — detects 10 frameworks (GetX, Riverpod, Bloc/Cubit, Provider, Dio, GoRouter, AutoRoute, Freezed, Hive, Drift) via pubspec dependencies, import statements, and AST superclass matching
- **ArchitectureAnalyzer** — maps directories to architectural layers, builds dependency graph, detects entry points including `main_*.dart` environment variants
- **ConventionAnalyzer** — tracks 15 file suffixes and 16 class suffixes with adoption rates
- **FilePurposeAnalyzer** — classifies every file's role (widget, model, service, bloc, test, generated, etc.)
- **MetricsAggregator** — computes averages, totals, top-5 largest files, files without comments

### Output Generators
- **ClaudeMdGenerator** — generates `CLAUDE.md` for AI agents (<20KB) with project overview, architecture, conventions, dependencies, and code health
- **AiContextGenerator** — generates `.ai-context/` with 6 structured JSON files (architecture, files, patterns, conventions, metrics, todos)

### MCP Server (6 tools)
- `get_architecture` — project type, layers, dependency graph, entry points
- `get_file_purpose(path)` — purpose and metrics for a specific file
- `get_dependencies(package?)` — package dependencies, optionally filtered
- `get_conventions` — naming patterns and suffix adoption
- `get_todos(severity?)` — TODO/FIXME items, optionally filtered
- `get_project_structure(section?)` — full project structure markdown with section-based querying (returns summary by default, or a specific section like "frameworks" or "architecture")
- **--watch mode** — re-analyzes on .dart file changes with 2-second debounce

### CLI Commands
- `analyze` — original behavior, backward compatible (no subcommand defaults to this)
- `claude-md` — generates CLAUDE.md + baseline
- `ai-context` — generates .ai-context/ + CLAUDE.md + baseline
- `mcp-server` — starts MCP server + baseline

### Quality Improvements
- Filters macOS `._*` metadata files from analysis and directory trees
- Import-based framework detection (Freezed, GoRouter, Hive, Dio now show file evidence)
- Broader entry point detection (`main_development.dart`, `main_staging.dart`, `main_production.dart`)
- Graceful handling of non-UTF-8 files (skips binary/metadata files instead of crashing)

### New Dependencies
- `yaml: ^3.1.3` — pubspec.yaml parsing
- `mcp_dart: ^2.1.0` — MCP server protocol (official Dart Labs SDK)
- `watcher: ^1.1.0` — file watching for --watch mode

## 1.0.3

- Dependencies updated
- Dart version upgraded
- More Optimized

## 1.0.2

- Code optimized
- Proper documentations for better understanding

## 1.0.1

- File Statistics to count of total files, directories, and Dart files.
- TODO and FIXME Comments to scan files for TODO and FIXME comments and list them in a separate collapsible section.
- Dependency Analysis to list all external package dependencies used in the project.
- Code Metrics to calculate and display simple code metrics like lines of code, comment percentage, etc.

## 1.0.0

- Initial version.
- Generate project structure markdown file.
- Add path comments to Dart files.
- List imports for each file in the project structure.
- Collapsable imports for clear understanding of the project structure.
