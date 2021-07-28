import 'package:ilox/interpreter.dart';
import 'package:ilox/lox_callable.dart';
import 'package:ilox/lox_function.dart';
import 'package:ilox/lox_instance.dart';

class LoxClass implements LoxCallable {
  final String name;
  final Map<String, LoxFunction> methods;
  LoxClass(this.name, this.methods);

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
    return null;
  }
}
