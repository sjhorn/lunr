import 'package:lunr/token_set.dart';

typedef BuilderStack = List<BuilderFrame>;

class BuilderFrame {
  TokenSet parent;
  String char;
  TokenSet child;

  BuilderFrame({
    required this.parent,
    required this.char,
    required this.child,
  });
}

class TokenSetBuilder {
  String previousWord = '';
  TokenSet root = TokenSet();
  BuilderStack uncheckedNodes = [];
  Map<String, TokenSet> minimizedNodes = {};

  TokenSetBuilder();

  insert(String word) {
    TokenSet node;
    int commonPrefix = 0;

    if (word.compareTo(previousWord) < 0) {
      throw Exception("Out of order word insertion");
    }

    for (var i = 0; i < word.length && i < previousWord.length; i++) {
      if (word[i] != previousWord[i]) {
        break;
      }
      commonPrefix++;
    }

    minimize(commonPrefix);

    if (uncheckedNodes.isEmpty) {
      node = root;
    } else {
      node = uncheckedNodes[uncheckedNodes.length - 1].child;
    }

    for (var i = commonPrefix; i < word.length; i++) {
      var nextNode = TokenSet(), char = word[i];

      node.edges[char] = nextNode;

      uncheckedNodes.add(BuilderFrame(
        parent: node,
        char: char,
        child: nextNode,
      ));

      node = nextNode;
    }

    node.isFinal = true;
    previousWord = word;
  }

  finish() {
    minimize(0);
  }

  minimize(int downTo) {
    for (int i = uncheckedNodes.length - 1; i >= downTo; i--) {
      BuilderFrame node = uncheckedNodes[i];
      String childKey = node.child.toString();

      if (minimizedNodes.containsKey(childKey)) {
        node.parent.edges[node.char] = minimizedNodes[childKey]!;
      } else {
        // Cache the key for this node since
        // we know it can't change anymore
        node.child.cachedString = childKey;

        minimizedNodes[childKey] = node.child;
      }

      uncheckedNodes.removeLast();
    }
  }
}
