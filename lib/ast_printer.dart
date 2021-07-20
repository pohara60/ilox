import 'package:ilox/expr.dart';

// import 'package:ilox/token.dart';
// import 'package:ilox/token_type.dart';

// void main(List<String> args) {
//   Expr expression = Binary(
//       Unary(Token(TokenType.MINUS, '-', null, 1), Literal(123)),
//       Token(TokenType.STAR, '*', null, 1),
//       Grouping(Literal(45.67)));

//   print(AstPrinter().print(expression) + '\n');
// }

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
