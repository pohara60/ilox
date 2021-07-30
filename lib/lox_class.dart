import 'package:ilox/interpreter.dart';
import 'package:ilox/lox_callable.dart';
import 'package:ilox/lox_function.dart';
import 'package:ilox/lox_instance.dart';
import 'package:ilox/token.dart';

class LoxClass implements LoxCallable {
  final String name;
  final LoxClass superclass;
  final Map<String, LoxFunction> methods;
  final Map<String, LoxFunction> functions;
  LoxClass(this.name, this.superclass, this.methods, this.functions);

  @override
  String toString() {
    return name;
  }

  @override
  int arity() {
    var initializer = findMethod('init');
    if (initializer == null) return 0;
    return initializer.arity();
  }

  @override
  Object call(Interpreter interpreter, List<Object> arguments) {
    var instance = LoxInstance(this);
    var initializer = findMethod('init');
    if (initializer != null) {
      initializer.bind(instance).call(interpreter, arguments);
    }
    return instance;
  }

  LoxFunction findMethod(String name) {
    if (methods.containsKey(name)) {
      return methods[name];
    }
    if (superclass != null) {
      return superclass.findMethod(name);
    }
    return null;
  }

  Object get(Token name) {
    var method = findFunction(name.lexeme);
    if (method != null) return method.bind(null);
    throw RuntimeError(name, "Undefined function '${name.lexeme}'.");
  }

  LoxFunction findFunction(String name) {
    if (functions.containsKey(name)) {
      return functions[name];
    }
    if (superclass != null) {
      return superclass.findFunction(name);
    }
    return null;
  }
}
