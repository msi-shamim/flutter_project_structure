# flutter_project_structure — Product Vision

> One command. Every AI agent understands your project instantly. No matter how big.

---

## The Problem (2026)

Developers use AI agents (Claude Code, Cursor, Copilot) daily, but these agents struggle with large codebases:
- **Context limits** — agent reads 50 files, misses the other 200
- **No architecture awareness** — suggests code that breaks established patterns
- **No convention knowledge** — generates inconsistent naming, file placement
- **Every session starts from scratch** — developer repeats "here's my project structure..."
- **Onboarding takes days** — new team members explore folders blindly

## The Solution

`flutter_project_structure` bridges your codebase and AI agents. One command makes your entire project AI-ready:

```bash
dart run flutter_project_structure ai-context
```

That single command:
1. Adds `// Path: lib/src/...` comments to every Dart file (AI knows where every file sits)
2. Generates `project_structure.md` (comprehensive directory tree with full analysis)
3. Generates `CLAUDE.md` (<20KB AI-optimized summary agents read automatically)
4. Generates `.ai-context/` (6 structured JSON files for programmatic querying)

The result: your AI agent starts every session already understanding your project's architecture, frameworks, conventions, and file purposes.

---

## v2.0.0 — What Ships

### The Baseline (every command produces this)

No matter which command you run — `analyze`, `claude-md`, `ai-context`, or `mcp-server` — you always get:

- **Path comments** in every Dart file (`// Path: lib/module/auth/login_screen.dart`)
- **project_structure.md** with directory tree + all analysis sections

This is the core value of the package. The specific command just adds its output on top.

### Output Formats

#### 1. `project_structure.md` — The Complete Reference
The most comprehensive output. Contains the full directory tree with file icons, collapsible imports, and all 10 analysis sections (project type, frameworks, architecture, statistics, TODOs, dependencies, code metrics, conventions, file purposes, aggregated metrics).

For a 384-file Flutter app, this generates ~250KB of detailed analysis. Too large for AI to consume at once, but perfect as a reference that the MCP server can serve section-by-section.

#### 2. `CLAUDE.md` — AI Agent Context File
A compact, AI-optimized summary (<20KB) designed for AI agents to read at the start of every session. Contains:
- Project type and tech stack
- Architecture layers and entry points
- Directory structure (compressed, 3 levels deep)
- Naming conventions and patterns
- Top 15 package dependencies by usage
- Code health summary and technical debt

Claude Code, Cursor, and similar tools read `CLAUDE.md` automatically from the project root.

#### 3. `.ai-context/` — Structured JSON
6 machine-readable files for programmatic consumption:

```
.ai-context/
  architecture.json    — project type, layers, dependency graph, entry points
  files.json           — every file with purpose, LOC, classes, methods, comment ratio
  patterns.json        — detected frameworks with file evidence
  conventions.json     — naming patterns with counts
  metrics.json         — aggregated code health
  todos.json           — structured TODO/FIXME index
```

#### 4. MCP Server — Live Querying
6 tools over stdio JSON-RPC for real-time AI agent queries:

| Tool | What it returns |
|------|----------------|
| `get_architecture` | Project type, layers, dependency graph, entry points |
| `get_file_purpose(path)` | Purpose and metrics for a specific file |
| `get_dependencies(package?)` | Package dependencies, optionally filtered |
| `get_conventions` | Naming patterns and suffix adoption rates |
| `get_todos(severity?)` | TODO/FIXME items, optionally filtered |
| `get_project_structure(section?)` | Sections from project_structure.md on demand |

The `get_project_structure` tool solves the "too large for AI" problem — the agent first asks for a summary (section names + line counts), then drills into specific sections as needed.

Optional `--watch` mode re-analyzes when `.dart` files change (2-second debounce).

---

## Smart Detection

### Framework Detection (3 strategies)
1. **Pubspec scanning** — checks `dependencies` and `dev_dependencies` for known packages
2. **Import analysis** — scans `import 'package:dio/dio.dart'` statements to count actual usage per file
3. **AST superclass matching** — detects `extends Bloc`, `extends Cubit`, `extends GetxController`, etc.

Detects: GetX, Riverpod, Bloc/Cubit, Provider, Dio, GoRouter, AutoRoute, Freezed, Hive, Drift.

### Entry Point Detection
Finds `main.dart`, `app.dart`, and environment variants common in Flutter projects:
- `main_development.dart`
- `main_staging.dart`
- `main_production.dart`
- Any `main_*.dart` file

### Architecture Layer Mapping
Maps 27+ directory names to architectural layers:
- Domain layers: core, data, domain, presentation
- Clean/MVVM/MVC: models, services, controllers, views, widgets, repositories, providers
- BLoC pattern: blocs, cubits
- Feature-based: screens, pages
- Utilities: utils, helpers

Builds a directed dependency graph showing which layers import from which.

---

## Implementation (All Completed)

| Phase | What | Status |
|-------|------|--------|
| 1 | FileAnalyzer interface, AnalysisPipeline, ProjectContext | Done |
| 2 | 6 new analyzers (ProjectType, Framework, Architecture, Convention, FilePurpose, Metrics) | Done |
| 3 | ClaudeMdGenerator, AiContextGenerator | Done |
| 4 | MCP Server with 6 tools + watch mode | Done |
| 5 | CLI commands (analyze, claude-md, ai-context, mcp-server) | Done |
| 6 | All commands produce baseline (path comments + project_structure.md) | Done |
| 7 | Testing (26 tests) + docs + verified against 384-file production app | Done |

---

## Key Design Decisions

1. **Parse once** — each file parsed to AST once, shared across all analyzers (3x faster than per-analyzer scanning)
2. **Every command = full setup** — no matter which command you run, you always get path comments + project_structure.md as baseline
3. **`generate()` returns ProjectContext** — single call gives you file modifications + markdown output + analysis data for generators (no double-scanning)
4. **Backward compatible** — no subcommand = v1.x `analyze` behavior
5. **Size-managed outputs** — CLAUDE.md stays under 20KB; MCP serves project_structure.md section-by-section
6. **MCP over stdio** — standard protocol, works with Claude Code, Cursor, any MCP client
7. **Graceful error handling** — skips non-UTF-8 files (macOS metadata, binary files) instead of crashing

---

## The Bigger Picture

```
flutter_monorepo              -> Creates the project (Day 0)
flutter_project_structure     -> Keeps AI agents informed as it grows (Day 1 -> Day 1000)
```

Together, these two tools cover the full Flutter developer lifecycle — from scaffolding to ongoing AI-assisted development. No other pub.dev packages do this.
