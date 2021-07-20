import 'package:ilox/token.dart';

abstract class Expr {
  T accept<T>(Visitor<T> visitor);
}

abstract class Visitor<T> {
  T visitBinaryExpr(Binary expr);
  T visitGroupingExpr(Grouping expr);
  T visitLiteralExpr(Literal expr);
  T visitUnaryExpr(Unary expr);
}

class Binary extends Expr {
  Binary (
    this.left,
    this.operator,
    this.right,
  );
  final Expr left;
  final Token operator;
  final Expr right;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitBinaryExpr(this);
  }
}

class Grouping extends Expr {
  Grouping (
    this.expression,
  );
  final Expr expression;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitGroupingExpr(this);
  }
}

class Literal extends Expr {
  Literal (
    this.value,
  );
  final Object value;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitLiteralExpr(this);
  }
}

class Unary extends Expr {
  Unary (
    this.operator,
    this.right,
  );
  final Token operator;
  final Expr right;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitUnaryExpr(this);
  }
}
