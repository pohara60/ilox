import 'package:ilox/expr.dart';

class AstPrinter implements Visitor<String> {
  String print(Expr expr) {
    return expr.accept(this);
  }

  @override
  String visitBinaryExpr(Binary expr) {
    return parenthesize(expr.operator.lexeme, expr.left, expr.right);
  }

  @override
  String visitGroupingExpr(Grouping expr) {
    return parenthesize('group', expr.expression);
  }

  @override
  String visitLiteralExpr(Literal expr) {
    if (expr.value == null) return 'nil';
    return expr.value.toString();
  }

  @override
  String visitUnaryExpr(Unary expr) {
    return parenthesize(expr.operator.lexeme, expr.right);
  }

  String parenthesize(String name, Expr expr, [Expr expr2]) {
    var buffer = StringBuffer();

    buffer.write('(');
    buffer.write(name);
    buffer.write(' ');
    buffer.write(expr.accept(this));
    if (expr2 != null) {
      buffer.write(' ');
      buffer.write(expr2.accept(this));
    }
    buffer.write(')');

    return buffer.toString();
  }
}
