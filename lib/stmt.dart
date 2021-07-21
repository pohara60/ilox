import 'package:ilox/expr.dart';
import 'package:ilox/token.dart';

abstract class Stmt {
  T accept<T>(StmtVisitor<T> visitor);
}

abstract class StmtVisitor<T> {
  T visitBlockStmt(Block stmt);
  T visitIfStmt(If stmt);
  T visitWhileStmt(While stmt);
  T visitExpressionStmt(Expression stmt);
  T visitPrintStmt(Print stmt);
  T visitVarStmt(Var stmt);
}

class Block extends Stmt {
  Block (
    this.statements,
  );
  final List<Stmt> statements;

  @override
  T accept<T>(StmtVisitor<T> visitor) {
    return visitor.visitBlockStmt(this);
  }
}

class If extends Stmt {
  If (
    this.condition,
    this.thenBranch,
    this.elseBranch,
  );
  final Expr condition;
  final Stmt thenBranch;
  final Stmt elseBranch;

  @override
  T accept<T>(StmtVisitor<T> visitor) {
    return visitor.visitIfStmt(this);
  }
}

class While extends Stmt {
  While (
    this.condition,
    this.body,
  );
  final Expr condition;
  final Stmt body;

  @override
  T accept<T>(StmtVisitor<T> visitor) {
    return visitor.visitWhileStmt(this);
  }
}

class Expression extends Stmt {
  Expression (
    this.expression,
  );
  final Expr expression;

  @override
  T accept<T>(StmtVisitor<T> visitor) {
    return visitor.visitExpressionStmt(this);
  }
}

class Print extends Stmt {
  Print (
    this.expression,
  );
  final Expr expression;

  @override
  T accept<T>(StmtVisitor<T> visitor) {
    return visitor.visitPrintStmt(this);
  }
}

class Var extends Stmt {
  Var (
    this.name,
    this.initializer,
  );
  final Token name;
  final Expr initializer;

  @override
  T accept<T>(StmtVisitor<T> visitor) {
    return visitor.visitVarStmt(this);
  }
}
