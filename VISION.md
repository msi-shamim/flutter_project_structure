# flutter_project_structure — Product Vision

> Every AI agent understands your project instantly. No matter how big.

---

## The Problem (2026)

Developers use AI agents (Claude Code, Cursor, Copilot) daily, but these agents struggle with large codebases:
- **Context limits** — agent reads 50 files, misses the other 200
- **No architecture awareness** — suggests code that breaks established patterns
- **No convention knowledge** — generates inconsistent naming, file placement
- **Every session starts from scratch** — developer repeats "here's my project structure..."
- **Onboarding takes days** — new team members explore folders blindly

## The Solution

`flutter_project_structure` becomes the bridge between codebases and AI agents. One command generates everything an AI needs to understand any project:

```bash
flutter_project_structure ai-context
```

---

## v2.0.0 — AI Agent Integration

### Three New Outputs

#### 1. `CLAUDE.md` — Auto-Generated AI Context File
Goes in project root. Claude Code, Cursor, and similar tools read this automatically on every conversation.

Contains:
- Project type (monorepo / single app / package / plugin)
- Tech stack detection (GetX, Riverpod, Bloc, Dio, etc.)
- Architecture summary (layers, entry points, dependency graph)
- Directory structure (compressed, 2 levels deep with file counts)
- Detected conventions and rules
- Package dependencies
- Technical debt summary

Size target: <4KB small projects, <20KB enterprise monorepos.

#### 2. `.ai-context/` — Structured JSON Directory
Machine-readable context for programmatic consumption:

```
.ai-context/
├── architecture.json    # layers, dependency graph, entry points
├── files.json           # every file with purpose, imports, public API
├── patterns.json        # detected frameworks with usage details
├── conventions.json     # naming rules with confidence levels
├── metrics.json         # code health aggregates
└── todos.json           # structured technical debt index
```

#### 3. MCP Server — Live Query Interface
Any AI agent connecting via MCP gets instant project understanding without reading source files:

```bash
flutter_project_structure mcp-server
flutter_project_structure mcp-server --watch  # re-analyzes on file changes
```

5 tools exposed:
- `get_architecture` — project structure, layers, dependency graph
- `get_file_purpose(path)` — what a specific file does
- `get_dependencies(package?)` — who depends on what
- `get_conventions` — detected naming/coding patterns
- `get_todos(severity?)` — technical debt index

---

## Implementation Phases

### Phase 1: Foundation Refactoring
**Goal:** Parse each file once (currently 3x), create shared analysis pipeline.

- Create `FileAnalyzer` abstract interface
- Create `AnalysisPipeline` — single-pass file processing orchestrator
- Create `ProjectContext` — aggregated results data class
- Refactor 4 existing analyzers (FileStatistics, TodoComments, DependencyAnalysis, CodeMetrics) to implement FileAnalyzer and receive pre-parsed CompilationUnit
- Refactor CLI to use `CommandRunner` with subcommands (backward compatible)

**Verification:** Existing tests pass, `project_structure.md` output identical to v1.x.

### Phase 2: New Analyzers
All implement `FileAnalyzer` interface. Can be built independently.

| Analyzer | Detects | How |
|----------|---------|-----|
| `ProjectTypeDetector` | Monorepo/app/package/plugin | Multiple pubspec.yaml, melos.yaml, flutter key |
| `FrameworkDetector` | GetX/Riverpod/Bloc/Provider/etc | Pubspec deps + AST superclass checks |
| `ArchitectureAnalyzer` | Layers, dependency graph, entry points | Directory naming + internal import graph |
| `ConventionAnalyzer` | Naming patterns, file suffixes | Aggregate class/file name analysis |
| `FilePurposeAnalyzer` | Each file's role (widget/model/service) | Directory context + class hierarchy |
| `MetricsAggregator` | Health scores | Reuses existing metrics data |

### Phase 3: Output Generators
- `ClaudeMdGenerator` — generates `CLAUDE.md`
- `AiContextGenerator` — generates `.ai-context/` directory with 6 JSON files

### Phase 4: MCP Server
- JSON-RPC 2.0 over stdio (standard MCP protocol)
- 5 tools: get_architecture, get_file_purpose, get_dependencies, get_conventions, get_todos
- Optional `--watch` mode: re-analyzes on file changes

### Phase 5: CLI Commands
```bash
# Existing (backward compatible)
flutter_project_structure
flutter_project_structure --root-dir=lib --output=custom.md

# New subcommands
flutter_project_structure ai-context     # CLAUDE.md + .ai-context/
flutter_project_structure claude-md      # CLAUDE.md only
flutter_project_structure mcp-server     # Start MCP server
flutter_project_structure mcp-server --watch
```

### Phase 6: Testing & Docs
- Unit tests for each new analyzer
- Integration tests on real Flutter projects
- README.md, CHANGELOG.md, example/main.dart updated
- Bump to v2.0.0, publish to pub.dev

---

## File Structure (v2.0.0)

```
lib/
  flutter_project_structure.dart              # MODIFY — new exports, pipeline
  src/
    file_analyzer.dart                        # CREATE — abstract interface
    analysis_pipeline.dart                    # CREATE — single-pass orchestrator
    project_context.dart                      # CREATE — aggregated results
    file_statistics.dart                      # MODIFY — implement FileAnalyzer
    todo_comments.dart                        # MODIFY — implement FileAnalyzer
    dependency_analysis.dart                  # MODIFY — implement FileAnalyzer
    code_metrics.dart                         # MODIFY — implement FileAnalyzer
    add_path_comments.dart                    # UNCHANGED
    analyzers/
      project_type_detector.dart              # CREATE
      framework_detector.dart                 # CREATE
      architecture_analyzer.dart              # CREATE
      convention_analyzer.dart                # CREATE
      file_purpose_analyzer.dart              # CREATE
      metrics_aggregator.dart                 # CREATE
    generators/
      claude_md_generator.dart                # CREATE
      ai_context_generator.dart               # CREATE
      mcp_server.dart                         # CREATE
    commands/
      analyze_command.dart                    # CREATE
      ai_context_command.dart                 # CREATE
      claude_md_command.dart                  # CREATE
      mcp_server_command.dart                 # CREATE
bin/
  flutter_project_structure.dart              # MODIFY — CommandRunner
```

---

## Key Design Decisions

1. **Parse once** — each file parsed to AST once, shared across all analyzers (3x performance)
2. **Backward compatible** — no subcommand = existing v1.x behavior
3. **Size-managed outputs** — CLAUDE.md capped ~20KB, JSON paginated for large projects
4. **MCP over stdio** — standard protocol, works with Claude Code, Cursor, any MCP client
5. **Read-only AI commands** — ai-context and claude-md never modify source files

---

## New Dependencies (v2.0.0)

```yaml
yaml: ^3.1.3           # parsing pubspec.yaml / melos.yaml
mcp_dart: ^2.1.0       # MCP server protocol (official Dart Labs SDK)
watcher: ^1.1.0         # --watch mode for MCP server
```

---

## Current State (v2.0.0)

All 6 phases implemented and shipped:
- Project structure visualization (markdown tree with file icons)
- Path comments injected into Dart files
- Import mapping per file (collapsible sections)
- File statistics (total files, LOC, largest/smallest)
- TODO/FIXME comment tracking with line numbers
- Package dependency analysis
- Code metrics (classes, methods, comment ratio)
- CLI with feature flags and CommandRunner subcommands
- Programmatic API (FlutterProjectStructure class)
- FileAnalyzer interface with single-pass AnalysisPipeline
- 6 new analyzers (ProjectType, Framework, Architecture, Convention, FilePurpose, MetricsAggregator)
- ClaudeMdGenerator (CLAUDE.md) and AiContextGenerator (.ai-context/ JSON)
- MCP server with 5 tools and --watch mode (built on mcp_dart SDK)
- `runAnalysis()` read-only method returning ProjectContext
- Published on pub.dev: https://pub.dev/packages/flutter_project_structure

---

## The Bigger Picture

```
flutter_monorepo              → Creates the project (Day 0)
flutter_project_structure     → Keeps AI agents informed as it grows (Day 1 → Day 1000)
```

Together, these two tools cover the full Flutter developer lifecycle — from scaffolding to ongoing AI-assisted development. No other pub.dev packages do this.
