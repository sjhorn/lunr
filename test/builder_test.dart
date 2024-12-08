import 'package:lunr/field_ref.dart';
import 'package:lunr/index.dart';
import 'package:lunr/token.dart';
import 'package:lunr/token_set.dart';
import 'package:lunr/vector.dart';
import 'package:test/test.dart';
import 'package:lunr/builder.dart' as lunr;
import 'package:lunr/pipeline.dart';
import 'assert.dart';

void main() {
  suite('lunr.Builder', () {
    suite('#add', () {
      late lunr.Builder builder;

      setup(() {
        builder = lunr.Builder();
      });

      test('field contains terms that clash with object prototype', () {
        builder.field('title');
        builder.add({'id': 'id', 'title': 'constructor'});

        Assert.deepProperty(builder.invertedIndex, 'constructor.title.id');

        Assert.deepEqual(
            builder.invertedIndex['constructor']?['title']['id'], {});

        Assert.equal(
            builder.fieldTermFrequencies[FieldRef.fromString('title/id')]![
                Token('constructor')],
            1);
      });

      test('field name clashes with object prototype', () {
        builder.field('constructor');
        builder.add({'id': 'id', 'constructor': 'constructor'});

        Assert.deepProperty(
            builder.invertedIndex, 'constructor.constructor.id');
        Assert.deepEqual(
            builder.invertedIndex['constructor']!['constructor']['id'], {});
      });

      test('document ref clashes with object prototype', () {
        builder.field('title');
        builder.add({'id': 'constructor', 'title': 'word'});

        Assert.deepProperty(builder.invertedIndex, 'word.title.constructor');
        Assert.deepEqual(
            builder.invertedIndex['word']!['title']['constructor'], {});
      });

      test('token metadata clashes with object prototype', () {
        pipelineFunction(t, _, __) {
          t.metadata['constructor'] = 'foo';
          return t;
        }

        Pipeline.registerFunction(pipelineFunction, 'test');
        builder.pipeline.add([pipelineFunction]);

        // the registeredFunctions object is global, is to prevent
        // polluting any other tests.
        Pipeline.registeredFunctions.remove('testt');

        builder.metadataWhitelist.add('constructor');

        builder.field('title');
        builder.add({'id': 'id', 'title': 'word'});
        Assert.deepProperty(builder.invertedIndex, 'word.title.id.constructor');
        Assert.deepEqual(
            builder.invertedIndex['word']!['title']['id']['constructor'],
            ['foo']);
      });

      test('extracting nested properties from a document', () {
        extractor(d) {
          return d['person']['name'];
        }

        builder.field('name', {'extractor': extractor});

        builder.add({
          'id': 'id',
          'person': {'name': 'bob'}
        });

        Assert.deepProperty(builder.invertedIndex, 'bob.name.id');
      });
    });

    suite('#field', () {
      test('defining fields to index', () {
        lunr.Builder builder = lunr.Builder();
        builder.field('foo');
        Assert.property(builder.fields, 'foo');
      });

      test('field with illegal characters', () {
        var builder = lunr.Builder();
        Assert.throws(() {
          builder.field('foo/bar');
        });
      });
    });

    suite('#ref', () {
      test('default reference', () {
        var builder = lunr.Builder();
        Assert.equal('id', builder.ref);
      });

      test('defining a reference field', () {
        var builder = lunr.Builder();
        builder.ref = 'foo';
        Assert.equal('foo', builder.ref);
      });
    });

    suite('#b', () {
      test('default value', () {
        var builder = lunr.Builder();
        Assert.equal(0.75, builder.b);
      });

      test('values less than zero', () {
        var builder = lunr.Builder();
        builder.b = -1;
        Assert.equal(0, builder.b);
      });

      test('values higher than one', () {
        var builder = lunr.Builder();
        builder.b = 1.5;
        Assert.equal(1, builder.b);
      });

      test('value within range', () {
        var builder = lunr.Builder();
        builder.b = 0.5;
        Assert.equal(0.5, builder.b);
      });
    });

    suite('#k1', () {
      test('default value', () {
        var builder = lunr.Builder();
        Assert.equal(1.2, builder.k1);
      });

      test('values less than zero', () {
        var builder = lunr.Builder();
        builder.k1 = 1.6;
        Assert.equal(1.6, builder.k1);
      });
    });

    // suite('#use',  () {
    //   setup( () {
    //     builder = lunr.Builder();
    //   })

    //   test('calls plugin ',  () {
    //     var wasCalled = false,
    //         plugin =  () { wasCalled = true }

    //     builder.use(plugin)
    //     Assert.isTrue(wasCalled)
    //   })

    //   test('sets context to the builder instance',  () {
    //     var context = null,
    //         plugin =  () { context = }

    //     builder.use(plugin)
    //     Assert.equal(context, builder)
    //   })

    //   test('passes builder as first argument',  () {
    //     var arg = null,
    //         plugin =  (a) { arg = a }

    //     builder.use(plugin)
    //     Assert.equal(arg, builder)
    //   })

    //   test('forwards arguments to the plugin',  () {
    //     var args = null,
    //         plugin =  () { args = [].slice.call(arguments) }

    //     builder.use(plugin, 1, 2, 3)
    //     Assert.deepEqual(args, [builder, 1, 2, 3])
    //   })
    // })

    suite('#build', () {
      late lunr.Builder builder;
      setUp(() {
        builder = lunr.Builder();
        var doc = {'id': 'id', 'title': 'test', 'body': 'missing'};

        builder.ref = 'id';
        builder.field('title');
        builder.add(doc);
        builder.build();
      });

      test('adds tokens to invertedIndex', () {
        Assert.deepProperty(builder.invertedIndex, 'test.title.id');
      });

      test('builds a vector space of the document fields', () {
        Assert.property(builder.fieldVectors, FieldRef.fromString('title/id'));

        Assert.instanceOf<Vector>(
            builder.fieldVectors[FieldRef.fromString('title/id')]);
      });

      test('skips fields not defined for indexing', () {
        Assert.notProperty(builder.invertedIndex, 'missing');
      });

      test('builds a token set for the corpus', () {
        var needle = TokenSet.fromString('test');
        Assert.include(builder.tokenSet.intersect(needle).toArray(), 'test');
      });

      test('calculates document count', () {
        Assert.equal(1, builder.documentCount);
      });

      test('calculates average field length', () {
        Assert.equal(1, builder.averageFieldLength['title']);
      });

      test('index returned', () {
        var builder = lunr.Builder();
        var doc = {'id': 'id', 'title': 'test', 'body': 'missing'};

        builder.ref = 'id';
        builder.field('title');
        builder.add(doc);
        Assert.instanceOf<Index>(builder.build());
      });
    });
  });
}
