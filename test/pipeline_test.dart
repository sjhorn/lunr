import 'package:lunr/token.dart';
import 'package:test/test.dart';
import 'assert.dart';

import 'package:lunr/pipeline.dart' as lunr;
import 'package:lunr/pipeline.dart';

// Convert token list  back into list of string
extension TokenListExt on List<Token> {
  Iterable<String> get strings => map((e) => e.toString());
}

extension TokenListExt2 on List<Token?> {
  Iterable<String> get strings => map((e) => e.toString());
}

extension StringListExt on List<String> {
  List<Token> get tokens => map((e) => Token(e)).toList();
}

extension IntListExt on List<int> {
  List<Token> get tokens => map((e) => Token(e.toString())).toList();
}

void main() {
  suite('lunr.Pipeline', () {
    noop(token, i, tokens) => null;

    late Map<String, lunr.PipelineFunction> existingRegisteredFunctions;
    late Pipeline pipeline;

    setup(() {
      existingRegisteredFunctions = lunr.Pipeline.registeredFunctions;
      //existingWarnIfFunctionNotRegistered = lunr.Pipeline.warnIfFunctionNotRegistered

      lunr.Pipeline.registeredFunctions = {};
      //lunr.Pipeline.warnIfFunctionNotRegistered = noop

      pipeline = lunr.Pipeline();
    });

    teardown(() {
      lunr.Pipeline.registeredFunctions = existingRegisteredFunctions;
      //lunr.Pipeline.warnIfFunctionNotRegistered = existingWarnIfFunctionNotRegistered
    });

    suite('#add', () {
      test('add  to pipeline', () {
        pipeline.add([noop]);
        Assert.equal(1, pipeline.length);
      });

      test('add multiple s to the pipeline', () {
        pipeline.add([noop, noop]);
        Assert.equal(2, pipeline.length);
      });
    });

    suite('#remove', () {
      test(' exists in pipeline', () {
        pipeline.add([noop]);
        Assert.equal(1, pipeline.length);
        pipeline.remove(noop);
        Assert.equal(0, pipeline.length);
      });

      test(' does not exist in pipeline', () {
        fn(token, i, tokens) => null;
        pipeline.add([noop]);
        Assert.equal(1, pipeline.length);
        pipeline.remove(fn);
        Assert.equal(1, pipeline.length);
      });
    });

    suite('#before', () {
      fn(token, i, tokens) => null;

      test('other  exists', () {
        pipeline.add([noop]);
        pipeline.before(noop, fn);

        Assert.deepEqual([fn, noop], pipeline.stack);
      });

      test('other  does not exist', () {
        action() {
          pipeline.before(noop, fn);
        }

        Assert.throws(action);
        Assert.equal(0, pipeline.length);
      });
    });

    suite('#after', () {
      fn(token, i, tokens) => null;

      test('other  exists', () {
        pipeline.add([noop]);
        pipeline.after(noop, fn);

        Assert.deepEqual([noop, fn], pipeline.stack);
      });

      test('other  does not exist', () {
        action() {
          pipeline.after(noop, fn);
        }

        Assert.throws(action);
        Assert.equal(0, pipeline.length);
      });
    });

    suite('#run', () {
      test('calling each  for each token', () {
        int count1 = 0, count2 = 0;
        fn1(t, _, __) {
          count1++;
          return t;
        }

        fn2(t, _, __) {
          count2++;
          return t;
        }

        pipeline.add([fn1, fn2]);
        pipeline.run([1, 2, 3].tokens);

        Assert.equal(3, count1);
        Assert.equal(3, count2);
      });

      test('passes token to pipeline ', () {
        pipeline.add([
          (token, _, __) {
            Assert.equal('foo', token.toString());
            return null;
          }
        ]);

        pipeline.run(['foo'].tokens);
      });

      test('passes index to pipeline ', () {
        pipeline.add([
          (_, index, __) {
            Assert.equal(0, index);
            return null;
          }
        ]);

        pipeline.run([Token('foo')]);
      });

      test('passes entire token array to pipeline ', () {
        pipeline.add([
          (_, __, tokens) {
            Assert.deepEqual(['foo'], tokens.strings);
            return null;
          }
        ]);

        pipeline.run(['foo'].tokens);
      });

      test('passes output of one  as input to the next', () {
        pipeline.add([
          (t, _, __) {
            return Token(t.toString().toUpperCase());
          }
        ]);

        pipeline.add([
          (t, _, __) {
            Assert.equal('FOO', t.toString());
            return null;
          }
        ]);

        pipeline.run([Token('foo')]);
      });

      test('returns the results of the last ', () {
        pipeline.add([
          (t, _, __) {
            return Token(t.toString().toUpperCase());
          }
        ]);

        Assert.deepEqual(['FOO'], pipeline.run([Token('foo')]).strings);
      });

      test('filters out null, undefined and empty string values', () {
        List<Token?> tokens = [], output;

        // only pass on tokens for even token indexes
        // return null for 'foo'
        // return undefined for 'bar'
        // return '' for 'baz'
        pipeline.add([
          (t, i, _) {
            if (i == 4) {
              return null;
            } else if (i == 5) {
              return Token('');
            }
            if (i % 2 != 0) {
              return t;
            } else {
              return null;
            }
          }
        ]);

        pipeline.add([
          (t, _, __) {
            tokens.add(t);
            return t;
          }
        ]);

        output = pipeline.run(['a', 'b', 'c', 'd', 'foo', 'bar', 'baz'].tokens);

        Assert.sameMembers(['b', 'd'], tokens.strings);
        Assert.sameMembers(['b', 'd'], output.strings);
      });

      suite('expanding tokens', () {
        test('passed to output', () {
          pipeline.add([
            (t, _, __) {
              return [t, Token(t.toString().toUpperCase())];
            }
          ]);

          Assert.sameMembers(
              ["foo", "FOO"], pipeline.run(['foo'].tokens).strings);
        });

        test('not passed to same ', () {
          List<Token?> received = [];

          pipeline.add([
            (t, _, __) {
              received.add(t);
              return [t, Token('$t'.toUpperCase())];
            }
          ]);

          pipeline.run(['foo'].tokens);

          Assert.sameMembers(['foo'], received.strings);
        });

        test('passed to the next pipeline ', () {
          List<Token?> received = [];

          pipeline.add([
            (t, _, __) {
              return [t, Token('$t'.toUpperCase())];
            }
          ]);

          pipeline.add([
            (t, _, __) {
              received.add(t);
            }
          ]);

          pipeline.run(['foo'].tokens);

          Assert.sameMembers(['foo', 'FOO'], received.strings);
        });
      });
    });

    suite('#toJSON', () {
      test('returns an array of registered  labels', () {
        fn(token, i, tokens) => null;

        lunr.Pipeline.registerFunction(fn, 'fn');

        pipeline.add([fn]);

        Assert.sameMembers(['fn'], pipeline.toJSON());
      });
    });

    suite('.registerFunction', () {
      late PipelineFunction fn;
      setup(() {
        fn = (_, __, ___) => null;
      });

      test('adds a label property to the ', () {
        lunr.Pipeline.registerFunction(fn, 'fn');

        //Assert.equal('fn', fn.label)
        Assert.equal('fn', lunr.Pipeline.functionsToName[fn]);
      });

      test('adds  to the list of registered s', () {
        lunr.Pipeline.registerFunction(fn, 'fn');

        Assert.equal(fn, lunr.Pipeline.registeredFunctions['fn']);
      });
    });

    suite('.load', () {
      test('with registered s', () {
        fn(token, i, tokens) => null;
        List<String> serializedPipeline = ['fn'];
        Pipeline pipeline;

        lunr.Pipeline.registerFunction(fn, 'fn');

        pipeline = lunr.Pipeline.load(serializedPipeline);

        Assert.equal(1, pipeline.length);
        Assert.equal(fn, pipeline.stack[0]);
      });

      test('with unregisterd s', () {
        var serializedPipeline = ['fn'];

        Assert.throws(() {
          lunr.Pipeline.load(serializedPipeline);
        });
      });
    });

    suite('#reset', () {
      test('empties the stack', () {
        pipeline.add([(_, __, ___) => null]);

        Assert.equal(1, pipeline.length);

        pipeline.reset();

        Assert.equal(0, pipeline.length);
      });
    });
  });
}
