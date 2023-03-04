import 'package:test/test.dart';
import 'assert.dart';
import 'package:lunr/match_data.dart' as lunr;

void main() {
  suite('lunr.MatchData', () {
    suite('#combine', () {
      late lunr.MatchData match;
      setup(() {
        match = lunr.MatchData('foo', 'title', {
          'position': [1]
        });

        match.combine(lunr.MatchData('bar', 'title', {
          'position': [2]
        }));

        match.combine(lunr.MatchData('baz', 'body', {
          'position': [3]
        }));

        match.combine(lunr.MatchData('baz', 'body', {
          'position': [4]
        }));
      });

      test('#terms', () {
        Assert.sameMembers(['foo', 'bar', 'baz'], match.metadata.keys);
      });

      test('#metadata', () {
        Assert.deepEqual(match.metadata['foo']!['title']!['position'], [1]);
        Assert.deepEqual(match.metadata['bar']!['title']!['position'], [2]);
        Assert.deepEqual(match.metadata['baz']!['body']!['position'], [3, 4]);
      });

      test('does not mutate source data', () {
        var metadata = {
              'foo': [1]
            },
            matchData1 = lunr.MatchData('foo', 'title', metadata),
            matchData2 = lunr.MatchData('foo', 'title', metadata);

        matchData1.combine(matchData2);

        Assert.deepEqual(metadata['foo'], [1]);
      });
    });
  });
}
