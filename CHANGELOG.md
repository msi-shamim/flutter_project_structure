## 3.0.0 — Correct File Paths

Every path in every generated output is now correct. Previously, any file nested
more than one level below the analyzed root was reported under a wrong path —
which meant AI agents were handed file references that did not exist.

### The Bug

All eight analyzers derived a file's path with
`path.relative(file.path, from: path.dirname(path.dirname(file.path)))`, which
takes the parent of the file's *own* directory. That is only correct for files
sitting directly in `lib/`. Everything deeper silently lost its middle segments:

| File on disk | Reported before | Reported now |
|---|---|---|
| `lib/main.dart` | `lib\lib\main.dart` | `lib/main.dart` |
| `lib/src/widgets/foo_widget.dart` | `lib\widgets\foo_widget.dart` | `lib/src/widgets/foo_widget.dart` |

This affected `// Path:` comments, `project_structure.md`, `CLAUDE.md`,
`.ai-context/*.json`, and every MCP tool response — the entire surface the
package exists to produce. The README always documented the correct
`// Path: lib/src/...` format; the implementation now matches it.

### Fixed
- **Correct paths everywhere** — paths are now resolved once, relative to the
  project root (the directory holding `pubspec.yaml`), and reused by every
  analyzer and generator. All eight call sites shared the same broken formula;
  there is now a single source of truth, so they cannot drift apart again.
- **Forward slashes on every platform** — output is byte-identical on Windows
  and POSIX, so generated files no longer churn in diffs depending on who ran
  the tool, and paths are directly usable as file references by AI agents.
- **Test files are classified correctly on Windows** — `FilePurposeAnalyzer`
  checks for `/test/` in the path, which could never match backslash-separated
  paths. Fixed as a consequence of the normalization above.

### Breaking Changes
- `FileAnalyzer.analyzeFile` gained a required named parameter,
  `{required String relativePath}`. Custom analyzers must accept it and use it
  for any path they record instead of deriving one from `file.path`.
- `AnalysisPipeline` now requires a `projectRoot` argument:
  `AnalysisPipeline(analyzers, projectRoot: projectRoot)`.
- `addPathComment(File file)` is now `addPathComment(File file, String relativePath)`.
- Removed four previously `@Deprecated` methods — `FileStatistics.updateFileStats`,
  `TodoComments.findTodoComments`, `DependencyAnalysis.analyzeDependencies`, and
  `CodeMetrics.analyzeFileFromDisk`. Each took only a `File` and therefore could
  not resolve a correct path; use `analyzeFile` (or the pipeline) instead.
- `FlutterProjectStructure.outputFile` is now `String?` and defaults to `null`
  (meaning "the project root") rather than `'project_structure.md'`. See
  **Output Locations** below.

No command or flag was added, removed or renamed. Existing `// Path:` comments
in your source are rewritten in place on the next run.

### Output Locations
Outputs now default to the **project root** (beside `pubspec.yaml`) instead of
the current working directory. Previously, analyzing a project elsewhere —
`flutter_project_structure ai-context -r ../other/lib` — scattered
`project_structure.md` and `.ai-context/` into whatever directory you happened
to be standing in, while `CLAUDE.md` correctly followed the project. The three
outputs disagreed with each other; now they don't.

- `project_structure.md`, `.ai-context/` and `CLAUDE.md` all default to the
  project root.
- Passing an explicit `--output` / `--output-dir` still resolves against the
  current directory, as any CLI tool should.
- The CLI now prints the resolved absolute path it wrote to.

This only changes behaviour when the analyzed project is not the directory you
ran from. Running from your project root — the normal case — is unaffected.

### New Public API
- `relativePathFor(File file, String projectRoot)` — computes the canonical,
  forward-slash, project-root-relative path used throughout the package.
- `FlutterProjectStructure.outputFilePath` — the resolved path `generate()`
  writes the markdown to.
- `ClaudeMdGenerator.generate()` and `AiContextGenerator.generate()` now return
  the path they wrote to instead of `void`.

### Tests
- Expanded to 53 tests. A `Nested file paths` group covers a deliberately deep
  fixture: one test per analyzer, plus integration checks that no reported path
  is doubled, truncated, backslash-separated, or unresolvable on disk, and that
  the markdown and `.ai-context/` JSON refer to files identically. All ten fail
  against the old path formula.
- An `Output path resolution` group runs from an unrelated working directory to
  verify each output lands in the project root, and that an explicit path is
  still honoured relative to the current directory.
- Verified against a real 170-file Flutter project nested 7 levels deep. Before
  this release, 145 of its 161 reported paths pointed at files that did not
  exist and 9 files were dropped from the analysis entirely by key collisions;
  now all 170 resolve.

## 2.0.4

- Fixed cross-version analyzer API compatibility (works with analyzer 7.x through 12.x)
- Replaced `ClassDeclaration.name` and `NamedType.name2` with version-agnostic alternatives

## 2.0.3

- Synced all version references across docs, example, and MCP server

## 2.0.2

- Updated version references across all docs and MCP server

## 2.0.1

- Broadened `analyzer` dependency to support versions 7.x through 12.x
- Optimized pubspec description for pub.dev scoring
- Expanded test suite to 38 tests

## 2.0.0 — AI Agent Integration

The biggest update yet. One command now makes your entire Flutter project AI-ready — path comments in every file, comprehensive analysis, and multiple output formats for AI agents. **Save 90% of AI tokens** spent on project orientation. Handle 9x more projects with the same AI subscription.

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
