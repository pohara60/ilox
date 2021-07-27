import 'dart:convert';
import 'dart:io';

//import 'package:ilox/ast_printer.dart';
//import 'package:ilox/expr.dart';
import 'package:ilox/interpreter.dart';
import 'package:ilox/parser.dart';
import 'package:ilox/resolver.dart';
import 'package:ilox/scanner.dart';
import 'package:ilox/token.dart';
import 'package:ilox/token_type.dart';

class Lox {
  static final Interpreter interpreter = Interpreter();
  static bool hadError = false;
  static bool hadRuntimeError = false;

  static void runFile(String path) async {
    var file = File(path);
    var bytes = await file.readAsString(encoding: Encoding.getByName('ascii'));
    run(bytes);
    if (hadError) exit(65);
    if (hadRuntimeError) exit(70);
  }

  static void runPrompt() {
    while (true) {
      print('> ');
      var line = stdin.readLineSync(encoding: Encoding.getByName('ascii'));
      if (line == null) break;
      run(line, repl: true);
      hadError = false;
    }
  }

  static void run(String source, {bool repl = false}) {
    var scanner = Scanner(source);
    var tokens = scanner.scanTokens();

    var parser = Parser(tokens, repl);
    var statements = parser.parse();

    // Stop if there was a syntax error.
    if (hadError) return;

    var resolver = Resolver(interpreter);
    resolver.resolve(statements);

    // Stop if there was a semantic error.
    if (hadError) return;

    //print(AstPrinter().print(expression));
    interpreter.interpret(statements);
  }

  static void error(int line, String message) {
    report(line, '', message);
  }

  static void report(int line, String where, String message) {
    stderr.writeln('[line ${line.toString()}] Error$where: $message');
    hadError = true;
  }

  static void errorToken(Token token, String message) {
    if (token.type == TokenType.EOF) {
      report(token.line, ' at end', message);
    } else {
      report(token.line, " at '${token.lexeme}'", message);
    }
  }

  static void runtimeError(RuntimeError error) {
    stderr.writeln('${error.message}\n[line ${error.token.line}]');
    hadRuntimeError = true;
  }
}
