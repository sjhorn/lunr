import 'package:lunr/token_set_builder.dart';

import 'query.dart';
import 'token.dart';

class Frame {
  TokenSet node;
  TokenSet? qNode;
  TokenSet? output;
  int editsRemaining;
  String str;
  String prefix;
  TokenSet? child;

  Frame({
    required this.node,
    this.editsRemaining = 0,
    this.str = '',
    this.prefix = '',
    this.qNode,
    this.output,
    this.child,
  });
}

typedef Stack = List<Frame>;

class TokenSet {
  static int nextId = 1;

  bool isFinal = false;
  Map<String, TokenSet> edges = {};
  int id = nextId;
  String? cachedString;

  TokenSet() {
    nextId += 1;
  }

  factory TokenSet.fromArray(List arr) {
    var builder = TokenSetBuilder();

    for (dynamic item in arr) {
      builder.insert(item is Token ? item.toString() : item);
    }

    builder.finish();
    return builder.root;
  }

  factory TokenSet.fromClause(Clause clause) {
    if ((clause.editDistance ?? 0) > 0) {
      return TokenSet.fromFuzzyString(clause.term, clause.editDistance!);
    } else {
      return TokenSet.fromString(clause.term);
    }
  }

  factory TokenSet.fromFuzzyString(String str, int editDistance) {
    var root = TokenSet();

    Stack stack = [Frame(node: root, editsRemaining: editDistance, str: str)];

    while (stack.isNotEmpty) {
      Frame frame = stack.removeLast();

      // no edit
      if (frame.str.isNotEmpty) {
        String char = frame.str[0];
        TokenSet noEditNode;

        if (frame.node.edges.containsKey(char)) {
          noEditNode = frame.node.edges[char]!;
        } else {
          noEditNode = TokenSet();
          frame.node.edges[char] = noEditNode;
        }

        if (frame.str.length == 1) {
          noEditNode.isFinal = true;
        }

        stack.add(Frame(
            node: noEditNode,
            editsRemaining: frame.editsRemaining,
            str: frame.str.substring(1)));
      }

      if (frame.editsRemaining == 0) {
        continue;
      }

      TokenSet insertionNode;
      // insertion
      if (frame.node.edges.containsKey('*')) {
        insertionNode = frame.node.edges["*"]!;
      } else {
        insertionNode = TokenSet();
        frame.node.edges["*"] = insertionNode;
      }

      if (frame.str.isEmpty) {
        insertionNode.isFinal = true;
      }

      stack.add(Frame(
          node: insertionNode,
          editsRemaining: frame.editsRemaining - 1,
          str: frame.str));

      // deletion
      // can only do a deletion if we have enough edits remaining
      // and if there are characters left to delete in the string
      if (frame.str.length > 1) {
        stack.add(Frame(
            node: frame.node,
            editsRemaining: frame.editsRemaining - 1,
            str: frame.str.substring(1)));
      }

      // deletion
      // just removing the last character from the str
      if (frame.str.length == 1) {
        frame.node.isFinal = true;
      }

      // substitution
      // can only do a substitution if we have enough edits remaining
      // and if there are characters left to substitute
      TokenSet substitutionNode;
      if (frame.str.isNotEmpty) {
        if (frame.node.edges.containsKey("*")) {
          substitutionNode = frame.node.edges["*"]!;
        } else {
          substitutionNode = TokenSet();
          frame.node.edges["*"] = substitutionNode;
        }

        if (frame.str.length == 1) {
          substitutionNode.isFinal = true;
        }

        stack.add(Frame(
            node: substitutionNode,
            editsRemaining: frame.editsRemaining - 1,
            str: frame.str.substring(1)));
      }

      // transposition
      // can only do a transposition if there are edits remaining
      // and there are enough characters to transpose
      if (frame.str.length > 1) {
        var charA = frame.str[0], charB = frame.str[1];
        TokenSet transposeNode;

        if (frame.node.edges.containsKey(charB)) {
          transposeNode = frame.node.edges[charB]!;
        } else {
          transposeNode = TokenSet();
          frame.node.edges[charB] = transposeNode;
        }

        if (frame.str.length == 1) {
          transposeNode.isFinal = true;
        }

        stack.add(Frame(
            node: transposeNode,
            editsRemaining: frame.editsRemaining - 1,
            str: charA + frame.str.substring(2)));
      }
    }

    return root;
  }

  factory TokenSet.fromString(String str) {
    var node = TokenSet();
    TokenSet root = node;

    /*
    * Iterates through all characters within the passed string
    * appending a node for each character.
    *
    * When a wildcard character is found then a self
    * referencing edge is introduced to continually match
    * any number of any characters.
    */
    for (var i = 0, len = str.length; i < len; i++) {
      var char = str[i];
      bool isFinal = (i == len - 1);

      if (char == "*") {
        node.edges[char] = node;
        node.isFinal = isFinal;
      } else {
        var next = TokenSet();
        next.isFinal = isFinal;

        node.edges[char] = next;
        node = next;
      }
    }

    return root;
  }

  /// Converts this TokenSet into an array of strings
  /// contained within the TokenSet.
  ///
  /// This is not intended to be used on a TokenSet that
  /// contains wildcards, in these cases the results are
  /// undefined and are likely to cause an infinite loop.
  ///
  /// @returns {string[]}
  List<String> toArray() {
    List<String> words = [];

    Stack stack = [Frame(prefix: "", node: this)];

    while (stack.isNotEmpty) {
      var frame = stack.removeLast();
      var edges = frame.node.edges.keys.toList();
      int len = edges.length;

      if (frame.node.isFinal) {
        /* In Safari, at this point the prefix is sometimes corrupted, see:
       * https://github.com/olivernn/lunr.js/issues/279 Calling any
       * String.prototype method forces Safari to "cast" this string to what
       * it's supposed to be, fixing the bug. */
        frame.prefix[0];
        words.add(frame.prefix);
      }

      for (var i = 0; i < len; i++) {
        var edge = edges[i];

        stack.add(Frame(
            prefix: '${frame.prefix}$edge', node: frame.node.edges[edge]!));
      }
    }

    return words;
  }

  /// Generates a string representation of a TokenSet.
  ///
  /// This is intended to allow TokenSets to be used as keys
  /// in objects, largely to aid the construction and minimisation
  /// of a TokenSet. As such it is not designed to be a human
  /// friendly representation of the TokenSet.
  ///
  /// @returns {string}
  @override
  String toString() {
    // NOTE: Using Object.keys here as this.edges is very likely
    // to enter 'hash-mode' with many keys being added
    //
    // avoiding a for-in loop here as it leads to the function
    // being de-optimised (at least in V8). From some simple
    // benchmarks the performance is comparable, but allowing
    // V8 to optimize may mean easy performance wins in the future.

    if (cachedString != null) {
      return cachedString!;
    }

    String str = isFinal ? '1' : '0';
    List<String> labels = edges.keys.toList()..sort((a, b) => a.compareTo(b));
    int len = labels.length;

    for (var i = 0; i < len; i++) {
      var label = labels[i];
      TokenSet node = edges[label]!;

      str = '$str$label${node.id}';
    }

    return str;
  }

  /// Returns a new TokenSet that is the intersection of
  /// this TokenSet and the passed TokenSet.
  ///
  /// This intersection will take into account any wildcards
  /// contained within the TokenSet.
  ///
  /// @param {lunr.TokenSet} b - An other TokenSet to intersect with.
  /// @returns {lunr.TokenSet}
  TokenSet intersect(TokenSet b) {
    var output = TokenSet();
    Frame? frame;

    var stack = [Frame(qNode: b, output: output, node: this)];

    while (stack.isNotEmpty) {
      frame = stack.removeLast();

      // NOTE: As with the #toString method, we are using
      // Object.keys and a for loop instead of a for-in loop
      // as both of these objects enter 'hash' mode, causing
      // the function to be de-optimised in V8
      List<String> qEdges = frame.qNode!.edges.keys.toList();
      int qLen = qEdges.length;
      List<String> nEdges = frame.node.edges.keys.toList();
      int nLen = nEdges.length;

      for (var q = 0; q < qLen; q++) {
        var qEdge = qEdges[q];

        for (var n = 0; n < nLen; n++) {
          var nEdge = nEdges[n];

          if (nEdge == qEdge || qEdge == '*') {
            TokenSet node = frame.node.edges[nEdge]!;
            TokenSet qNode = frame.qNode!.edges[qEdge]!;
            bool isFinal = node.isFinal && qNode.isFinal;
            TokenSet? next;

            if (frame.output!.edges.containsKey(nEdge)) {
              // an edge already exists for this character
              // no need to create a new node, just set the finality
              // bit unless this node is already final
              next = frame.output!.edges[nEdge]!;
              next.isFinal = next.isFinal || isFinal;
            } else {
              // no edge exists yet, must create one
              // set the finality bit and insert it
              // into the output
              next = TokenSet();
              next.isFinal = isFinal;
              frame.output!.edges[nEdge] = next;
            }

            stack.add(Frame(qNode: qNode, output: next, node: node));
          }
        }
      }
    }
    return output;
  }
}
