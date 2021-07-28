import 'package:ilox/environment.dart';
import 'package:ilox/interpreter.dart';
import 'package:ilox/lox_callable.dart';
import 'package:ilox/lox_instance.dart';
import 'package:ilox/return.dart';
import 'package:ilox/stmt.dart';
import 'package:ilox/token.dart';

class LoxFunction implements LoxCallable {
  final Token name;
  final List<Token> parameters;
  final List<Stmt> body;
  final Environment closure;
  final bool isInitializer;
  LoxFunction(
      this.name, this.parameters, this.body, this.closure, this.isInitializer);

  @override
  Object call(Interpreter interpreter, List<Object> arguments) {
    var environment = Environment(closure);
    for (var i = 0; i < parameters.length; i++) {
      environment.define(parameters[i].lexeme, arguments[i]);
    }
    try {
      interpreter.executeBlock(body, environment);
    } on ReturnException catch (returnValue) {
      if (isInitializer) return closure.getAt(0, 'this');
      return returnValue.value;
    }
    if (isInitializer) return closure.getAt(0, 'this');
    return null;
  }

  LoxFunction bind(LoxInstance instance) {
    var environment = Environment(closure);
    environment.define('this', instance);
    return LoxFunction(name, parameters, body, environment, isInitializer);
  }

  @override
  int arity() {
    return parameters.length;
  }

  @override
  String toString() {
    if (name == null) return '<lambda>';
    return '<fn ${name.lexeme}>';
  }
}
