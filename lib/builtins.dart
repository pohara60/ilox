import 'package:ilox/interpreter.dart';
import 'package:ilox/lox_callable.dart';

import 'environment.dart';

void defineBuiltins(Environment globals) {
  globals.define('clock', clock);
}

class clock implements LoxCallable {
  @override
  int arity() {
    return 0;
  }

  @override
  Object call(Interpreter interpreter, List<Object> arguments) {
    return DateTime.now().millisecondsSinceEpoch / 1000.0;
  }

  @override
  String toString() {
    return '<native fn>';
  }
}
