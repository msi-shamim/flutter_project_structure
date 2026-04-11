## 2.0.0 — AI Agent Integration

### Architecture
- **FileAnalyzer interface** — Abstract interface for all analyzers with single-pass processing
- **AnalysisPipeline** — Reads and parses each file once, distributes to all registered analyzers (3x performance improvement)
- **ProjectContext** — Aggregated analysis results data class, consumed by generators and MCP tools
- **`runAnalysis()` method** — Read-only analysis returning ProjectContext (no source file modification)
- **CommandRunner-based CLI** — Backward compatible (no subcommand defaults to `analyze`)

### New Analyzers
- **ProjectTypeDetector** — Detects monorepo, plugin, flutter_app, or dart_package from pubspec.yaml
- **FrameworkDetector** — Detects GetX, Riverpod, Bloc/Cubit, Provider, Dio, GoRouter, AutoRoute, Freezed, Hive, Drift via pubspec + AST analysis
- **ArchitectureAnalyzer** — Detects architectural layers from directory naming, builds layer dependency graph, identifies entry points
- **ConventionAnalyzer** — Detects file and class naming patterns and suffix conventions
- **FilePurposeAnalyzer** — Classifies each file's role (widget, model, service, bloc, controller, etc.)
- **MetricsAggregator** — Computes aggregated health metrics (averages, totals, top-5 largest files)

### Output Generators
- **ClaudeMdGenerator** — Generates `CLAUDE.md` for AI agent context with project overview, architecture, conventions, dependencies, and code health (<20KB)
- **AiContextGenerator** — Generates `.ai-context/` directory with 6 structured JSON files: architecture.json, files.json, patterns.json, conventions.json, metrics.json, todos.json

### MCP Server
- **5 MCP tools** over stdio JSON-RPC: `get_architecture`, `get_file_purpose`, `get_dependencies`, `get_conventions`, `get_todos`
- **--watch mode** — Re-analyzes on .dart file changes with 2-second debounce
- Built on `mcp_dart` SDK (official Dart Labs)

### New CLI Subcommands
- `flutter_project_structure analyze` — Original behavior (backward compatible)
- `flutter_project_structure claude-md` — Generate CLAUDE.md only
- `flutter_project_structure ai-context` — Generate .ai-context/ + CLAUDE.md
- `flutter_project_structure mcp-server [--watch]` — Start MCP server

### New Dependencies
- `yaml: ^3.1.3` — pubspec.yaml parsing for project type and framework detection
- `mcp_dart: ^2.1.0` — MCP server protocol implementation
- `watcher: ^1.1.0` — File watching for --watch mode

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
