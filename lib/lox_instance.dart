import 'package:ilox/interpreter.dart';
import 'package:ilox/lox_class.dart';
import 'package:ilox/token.dart';

class LoxInstance {
  LoxClass klass;
  final fields = <String, Object>{};

  LoxInstance(LoxClass klass) {
    this.klass = klass;
  }

  Object get(Token name) {
    if (fields.containsKey(name.lexeme)) {
      return fields[name.lexeme];
    }
    var method = klass.findMethod(name.lexeme);
    if (method != null) return method.bind(this);
    throw RuntimeError(name, "Undefined property '${name.lexeme}'.");
  }

  void set(Token name, Object value) {
    fields[name.lexeme] = value;
  }

  @override
  String toString() {
    return '${klass.name} instance';
  }
}
