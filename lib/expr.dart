import 'package:ilox/stmt.dart';
import 'package:ilox/token.dart';

abstract class Expr {
  T accept<T>(ExprVisitor<T> visitor);
}

abstract class ExprVisitor<T> {
  T visitAssignExpr(Assign expr);
  T visitBinaryExpr(Binary expr);
  T visitLogicalExpr(Logical expr);
  T visitGroupingExpr(Grouping expr);
  T visitLiteralExpr(Literal expr);
  T visitUnaryExpr(Unary expr);
  T visitCallExpr(Call expr);
  T visitGetExpr(Get expr);
  T visitSetExpr(Set expr);
  T visitSuperExpr(Super expr);
  T visitThisExpr(This expr);
  T visitVariableExpr(Variable expr);
  T visitLambdaExpr(Lambda expr);
}

class Assign extends Expr {
  Assign (
    this.name,
    this.value,
  );
  final Token name;
  final Expr value;

  @override
  T accept<T>(ExprVisitor<T> visitor) {
    return visitor.visitAssignExpr(this);
  }
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
  T accept<T>(ExprVisitor<T> visitor) {
    return visitor.visitBinaryExpr(this);
  }
}

class Logical extends Expr {
  Logical (
    this.left,
    this.operator,
    this.right,
  );
  final Expr left;
  final Token operator;
  final Expr right;

  @override
  T accept<T>(ExprVisitor<T> visitor) {
    return visitor.visitLogicalExpr(this);
  }
}

class Grouping extends Expr {
  Grouping (
    this.expression,
  );
  final Expr expression;

  @override
  T accept<T>(ExprVisitor<T> visitor) {
    return visitor.visitGroupingExpr(this);
  }
}

class Literal extends Expr {
  Literal (
    this.value,
  );
  final Object value;

  @override
  T accept<T>(ExprVisitor<T> visitor) {
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
  T accept<T>(ExprVisitor<T> visitor) {
    return visitor.visitUnaryExpr(this);
  }
}

class Call extends Expr {
  Call (
    this.callee,
    this.paren,
    this.arguments,
  );
  final Expr callee;
  final Token paren;
  final List<Expr> arguments;

  @override
  T accept<T>(ExprVisitor<T> visitor) {
    return visitor.visitCallExpr(this);
  }
}

class Get extends Expr {
  Get (
    this.object,
    this.name,
  );
  final Expr object;
  final Token name;

  @override
  T accept<T>(ExprVisitor<T> visitor) {
    return visitor.visitGetExpr(this);
  }
}

class Set extends Expr {
  Set (
    this.object,
    this.name,
    this.value,
  );
  final Expr object;
  final Token name;
  final Expr value;

  @override
  T accept<T>(ExprVisitor<T> visitor) {
    return visitor.visitSetExpr(this);
  }
}

class Super extends Expr {
  Super (
    this.keyword,
    this.method,
  );
  final Token keyword;
  final Token method;

  @override
  T accept<T>(ExprVisitor<T> visitor) {
    return visitor.visitSuperExpr(this);
  }
}

class This extends Expr {
  This (
    this.keyword,
  );
  final Token keyword;

  @override
  T accept<T>(ExprVisitor<T> visitor) {
    return visitor.visitThisExpr(this);
  }
}

class Variable extends Expr {
  Variable (
    this.name,
  );
  final Token name;

  @override
  T accept<T>(ExprVisitor<T> visitor) {
    return visitor.visitVariableExpr(this);
  }
}

class Lambda extends Expr {
  Lambda (
    this.params,
    this.body,
  );
  final List<Token> params;
  final List<Stmt> body;

  @override
  T accept<T>(ExprVisitor<T> visitor) {
    return visitor.visitLambdaExpr(this);
  }
}
