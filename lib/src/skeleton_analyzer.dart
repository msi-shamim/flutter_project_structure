// lib/src/skeleton_analyzer.dart
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'file_analyzer.dart';

/// A single declaration in a file's skeleton: its signature, without any body.
class SkeletonEntry {
  SkeletonEntry({required this.kind, required this.signature, this.doc})
      : members = [];

  /// One of: class, mixin, extension, enum, typedef, constructor, method,
  /// field, function, value.
  final String kind;

  /// The declaration up to (but excluding) its body, without its doc comment.
  final String signature;

  /// First line of the doc comment, if any — the author's own summary of
  /// what this declaration is for, which is exactly what a body-less
  /// skeleton is otherwise missing.
  final String? doc;

  /// Nested declarations, for container kinds.
  final List<SkeletonEntry> members;

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'signature': signature,
        if (doc != null) 'doc': doc,
        if (members.isNotEmpty)
          'members': members.map((m) => m.toJson()).toList(),
      };

  void _render(StringBuffer buffer, int depth) {
    final summary = doc == null ? '' : '  // $doc';
    buffer.writeln('${'  ' * depth}$signature$summary');
    for (final member in members) {
      member._render(buffer, depth + 1);
    }
  }
}

/// The public shape of one file: every declaration, no bodies.
class FileSkeleton {
  FileSkeleton(this.path, this.declarations);

  final String path;
  final List<SkeletonEntry> declarations;

  /// Total declarations including nested members.
  int get declarationCount =>
      declarations.fold(0, (sum, d) => sum + 1 + _count(d.members));

  static int _count(List<SkeletonEntry> entries) =>
      entries.fold(0, (sum, e) => sum + 1 + _count(e.members));

  /// Indented plain-text rendering, the form an agent reads.
  String render() {
    final buffer = StringBuffer('$path\n');
    for (final declaration in declarations) {
      declaration._render(buffer, 1);
    }
    return buffer.toString();
  }

  List<Map<String, dynamic>> toJson() =>
      declarations.map((d) => d.toJson()).toList();
}

/// Extracts each file's declarations without their bodies.
///
/// A skeleton is what an agent needs to *use* a file — class names,
/// constructors, method signatures, fields — as opposed to what it needs to
/// *change* one. On real Flutter code this is roughly a tenth the size of the
/// source, so an agent can hold the shape of an entire project in context and
/// read full bodies only for the files it actually edits.
///
/// Bodies carry the behaviour, so a skeleton is a map, not a summary: it tells
/// you a widget exists and what it takes, not what it renders.
class SkeletonAnalyzer implements FileAnalyzer {
  /// file path → its skeleton.
  final Map<String, FileSkeleton> skeletons = {};

  /// Characters of source seen, for reporting compression.
  int sourceLength = 0;

  /// Characters of rendered skeleton produced.
  int skeletonLength = 0;

  /// How much smaller the skeletons are than the source, as a percentage.
  double get compressionRatio =>
      sourceLength == 0 ? 0 : (1 - skeletonLength / sourceLength) * 100;

  @override
  void analyzeFile(File file, String content, CompilationUnit? compilationUnit,
      {required String relativePath}) {
    if (compilationUnit == null) return;

    final visitor = _SkeletonVisitor(content);
    compilationUnit.accept(visitor);

    final skeleton = FileSkeleton(relativePath, visitor.declarations);
    skeletons[relativePath] = skeleton;

    sourceLength += content.length;
    skeletonLength += skeleton.render().length;
  }

  @override
  String toString() {
    if (skeletons.isEmpty) return 'No files analyzed for skeletons.';

    final declarations =
        skeletons.values.fold(0, (sum, s) => sum + s.declarationCount);

    return '- Files: ${skeletons.length}\n'
        '- Declarations: $declarations\n'
        '- Skeleton size: ${(skeletonLength / 1024).toStringAsFixed(1)} KB '
        'vs ${(sourceLength / 1024).toStringAsFixed(1)} KB of source '
        '(${compressionRatio.toStringAsFixed(1)}% smaller)\n';
  }
}

class _SkeletonVisitor extends RecursiveAstVisitor<void> {
  _SkeletonVisitor(this._source);

  /// Raw file content. Signatures are cut from this using AST offsets —
  /// never from `toSource()`, whose character positions do not line up with
  /// the original file and would leak body text into the signature.
  final String _source;

  final List<SkeletonEntry> declarations = [];
  SkeletonEntry? _enclosing;

  static final _whitespace = RegExp(r'\s+');

  String _clean(String source) => source.replaceAll(_whitespace, ' ').trim();

  String _slice(int start, int end) {
    if (start < 0 || end <= start || end > _source.length) return '';
    return _clean(_source.substring(start, end));
  }

  /// Where the declaration proper begins — after its doc comment, but
  /// including annotations, which carry real meaning (`@freezed`,
  /// `@Singleton()`).
  int _start(AnnotatedNode node) =>
      node.documentationComment?.end ?? node.offset;

  /// The author's own one-line summary, which is the piece a body-less
  /// skeleton would otherwise lose.
  String? _doc(AnnotatedNode node) {
    final comment = node.documentationComment;
    if (comment == null) return null;

    for (final token in comment.tokens) {
      final line =
          token.lexeme.replaceFirst(RegExp(r'^/{3,}\s*|^/\*\*\s*'), '').trim();
      if (line.isNotEmpty) return line;
    }
    return null;
  }

  /// Header of a class-like declaration: everything before its body brace.
  ///
  /// Scanning starts after any annotations so that a map literal inside
  /// metadata (`@Foo({'a': 1})`) is not mistaken for the body.
  String _header(AnnotatedNode node) {
    final afterMetadata =
        node.metadata.isEmpty ? _start(node) : node.metadata.last.end;
    final brace = _source.indexOf('{', afterMetadata);
    return brace < 0 ? _clean(node.toSource()) : _slice(_start(node), brace);
  }

  /// Signature of a member: source up to where its body begins, so that a
  /// named-parameter brace is never mistaken for the body.
  String _signature(AnnotatedNode node, int bodyOffset) =>
      _slice(_start(node), bodyOffset);

  void _container(AnnotatedNode node, String kind, void Function() descend) {
    final entry =
        SkeletonEntry(kind: kind, signature: _header(node), doc: _doc(node));
    _target.add(entry);

    final previous = _enclosing;
    _enclosing = entry;
    descend();
    _enclosing = previous;
  }

  List<SkeletonEntry> get _target => _enclosing?.members ?? declarations;

  void _add(AnnotatedNode node, String kind, String signature) {
    if (signature.isEmpty) return;
    _target
        .add(SkeletonEntry(kind: kind, signature: signature, doc: _doc(node)));
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) =>
      _container(node, 'class', () => super.visitClassDeclaration(node));

  @override
  void visitMixinDeclaration(MixinDeclaration node) =>
      _container(node, 'mixin', () => super.visitMixinDeclaration(node));

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) => _container(
      node, 'extension', () => super.visitExtensionDeclaration(node));

  @override
  void visitEnumDeclaration(EnumDeclaration node) =>
      _container(node, 'enum', () => super.visitEnumDeclaration(node));

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) =>
      _add(node, 'value', _slice(_start(node), node.end));

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) =>
      _add(node, 'constructor', _signature(node, node.body.offset));

  @override
  void visitMethodDeclaration(MethodDeclaration node) =>
      _add(node, 'method', _signature(node, node.body.offset));

  @override
  void visitFieldDeclaration(FieldDeclaration node) =>
      _add(node, 'field', _field(node));

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Functions nested inside a member body are implementation detail.
    if (_enclosing != null) return;
    _add(node, 'function',
        _signature(node, node.functionExpression.body.offset));
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) =>
      _add(node, 'typedef', _slice(_start(node), node.end));

  /// Fields keep their initialiser when it is short enough to be useful
  /// (constants, defaults) and drop it when it is really data.
  String _field(FieldDeclaration node) {
    final full = _slice(_start(node), node.end);
    if (full.length <= 120) return full;

    final equals = full.indexOf(' = ');
    return equals < 0 ? full : '${full.substring(0, equals)} = …;';
  }
}
