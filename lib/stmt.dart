import 'package:ilox/expr.dart';
import 'package:ilox/token.dart';

abstract class Stmt {
  T accept<T>(StmtVisitor<T> visitor);
}

abstract class StmtVisitor<T> {
  T visitBlockStmt(Block stmt);
  T visitIfStmt(If stmt);
  T visitWhileStmt(While stmt);
  T visitBreakStmt(Break stmt);
  T visitContinueStmt(Continue stmt);
  T visitExpressionStmt(Expression stmt);
  T visitPrintStmt(Print stmt);
  T visitVarStmt(Var stmt);
  T visitFuncStmt(Func stmt);
  T visitReturnStmt(Return stmt);
  T visitClassStmt(Class stmt);
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

class Break extends Stmt {
  Break (
  );

  @override
  T accept<T>(StmtVisitor<T> visitor) {
    return visitor.visitBreakStmt(this);
  }
}

class Continue extends Stmt {
  Continue (
  );

  @override
  T accept<T>(StmtVisitor<T> visitor) {
    return visitor.visitContinueStmt(this);
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

class Func extends Stmt {
  Func (
    this.name,
    this.params,
    this.body,
  );
  final Token name;
  final List<Token> params;
  final List<Stmt> body;

  @override
  T accept<T>(StmtVisitor<T> visitor) {
    return visitor.visitFuncStmt(this);
  }
}

class Return extends Stmt {
  Return (
    this.keyword,
    this.value,
  );
  final Token keyword;
  final Expr value;

  @override
  T accept<T>(StmtVisitor<T> visitor) {
    return visitor.visitReturnStmt(this);
  }
}

class Class extends Stmt {
  Class (
    this.name,
    this.superclass,
    this.methods,
    this.functions,
  );
  final Token name;
  final Variable superclass;
  final List<Func> methods;
  final List<Func> functions;

  @override
  T accept<T>(StmtVisitor<T> visitor) {
    return visitor.visitClassStmt(this);
  }
}
