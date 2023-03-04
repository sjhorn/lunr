import 'token.dart';
import 'utils.dart';

typedef PipelineFunction = dynamic Function(
    Token? token, int i, List<Token?> tokens);

class Pipeline {
  List<PipelineFunction> _stack = [];
  List<PipelineFunction> get stack => [..._stack];
  int get length => _stack.length;

  Pipeline();

  static Map<String, PipelineFunction> registeredFunctions = {};
  static Map<PipelineFunction, String> functionsToName = {};

  static registerFunction(PipelineFunction fn, String label) {
    if (registeredFunctions.containsKey(label)) {
      Utils.warn('Overwriting existing registered function: $label');
    }

    //fn.label = label;
    registeredFunctions[label] = fn;
    functionsToName[fn] = label;
  }

  static _warnIfFunctionNotRegistered(PipelineFunction fn) {
    var isRegistered = registeredFunctions
        .containsValue(fn); //(fn.label in registeredFunctions) && fn.label

    if (!isRegistered) {
      Utils.warn(
          'Function is not registered with pipeline. This may cause problems when serialising the index.\n$fn');
    }
  }

  factory Pipeline.load(List<String> json) {
    Pipeline pipeline = Pipeline();
    for (String fnName in json) {
      PipelineFunction? fn = Pipeline.registeredFunctions[fnName];
      if (fn != null) {
        pipeline.add([fn]);
      } else {
        throw Exception('Cannot load unregistered function: $fnName');
      }
    }
    return pipeline;
  }

  void add(List<PipelineFunction> fns) {
    for (PipelineFunction fn in fns) {
      _warnIfFunctionNotRegistered(fn);
      _stack.add(fn);
    }
  }

  void after(PipelineFunction existingFn, PipelineFunction newFn) {
    _warnIfFunctionNotRegistered(newFn);
    var pos = _stack.indexOf(existingFn);
    if (pos == -1) {
      throw Exception('Cannot find existingFn');
    }
    _stack.insert(pos + 1, newFn);
  }

  void before(PipelineFunction existingFn, PipelineFunction newFn) {
    _warnIfFunctionNotRegistered(newFn);

    var pos = _stack.indexOf(existingFn);
    if (pos == -1) {
      throw Exception('Cannot find existingFn');
    }
    _stack.insert(pos, newFn);
  }

  void remove(fn) {
    var pos = _stack.indexOf(fn);
    if (pos == -1) {
      return;
    }
    _stack.removeAt(pos);
  }

  List<Token?> run(List<Token?> tokens) {
    var stackLength = _stack.length;

    for (int i = 0; i < stackLength; i++) {
      PipelineFunction fn = _stack[i];
      List<Token?> memo = [];

      for (var j = 0; j < tokens.length; j++) {
        var result = fn(tokens[j], j, tokens);
        if (result == null || result.toString() == '') continue;

        if (result is List<Token?>) {
          memo.addAll(result);
        } else {
          memo.add(result);
        }
      }

      tokens = memo;
    }

    return tokens;
  }

  List<String> runString(String str, TokenMetaData metadata) {
    Token token = Token(str, metadata);

    return run([token]).map((t) => t.toString()).toList();
  }

  void reset() {
    _stack = [];
  }

  List<String> toJSON() => _stack.map((e) => functionsToName[e]!).toList();
}
