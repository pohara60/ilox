import 'package:ilox/interpreter.dart';
import 'package:ilox/token.dart';

class Environment {
  final Environment enclosing;
  final Map<String, Object> values = {};

  Environment([this.enclosing]);

  void define(String name, Object value) {
    values[name] = value;
  }

  Object get(Token name) {
    if (values.containsKey(name.lexeme)) {
      return values[name.lexeme];
    }
    if (enclosing != null) {
      return enclosing.get(name);
    }
    throw RuntimeError(name, "Undefined variable '${name.lexeme}'.");
  }

  Object getAt(int distance, String name) {
    return ancestor(distance).values[name];
  }

  void assignAt(int distance, Token name, Object value) {
    ancestor(distance).values[name.lexeme] = value;
  }

  Environment ancestor(int distance) {
    var environment = this;
    for (var i = 0; i < distance; i++) {
      environment = environment.enclosing;
    }
    return environment;
  }

  void assign(Token name, Object value) {
    if (values.containsKey(name.lexeme)) {
      values[name.lexeme] = value;
      return;
    }
    if (enclosing != null) {
      enclosing.assign(name, value);
      return;
    }
    throw RuntimeError(name, "Undefined variable '${name.lexeme}'.");
  }
}
