import 'package:ilox/environment.dart';
import 'package:ilox/interpreter.dart';
import 'package:ilox/lox_callable.dart';
import 'package:ilox/return.dart';
import 'package:ilox/stmt.dart';

class LoxFunction implements LoxCallable {
  final Func declaration;
  final Environment closure;
  LoxFunction(this.declaration, this.closure);

  @override
  Object call(Interpreter interpreter, List<Object> arguments) {
    var environment = Environment(closure);
    for (var i = 0; i < declaration.params.length; i++) {
      environment.define(declaration.params[i].lexeme, arguments[i]);
    }
    try {
      interpreter.executeBlock(declaration.body, environment);
    } on ReturnException catch (returnValue) {
      return returnValue.value;
    }
    return null;
  }

  @override
  int arity() {
    return declaration.params.length;
  }

  @override
  String toString() {
    return '<fn ${declaration.name.lexeme}>';
  }
}
