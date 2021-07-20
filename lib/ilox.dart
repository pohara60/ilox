import 'dart:convert';
import 'dart:io';

import 'package:ilox/scanner.dart';

class Lox {
  static bool hadError = false;

  static void runFile(String path) async {
    var file = File(path);
    var bytes = await file.readAsString(encoding: Encoding.getByName('ascii'));
    run(bytes);
    if (hadError) exit(65);
  }

  static void runPrompt() {
    while (true) {
      print('> ');
      var line = stdin.readLineSync(encoding: Encoding.getByName('ascii'));
      if (line == null) break;
      run(line);
      hadError = false;
    }
  }

  static void run(String source) {
    var scanner = Scanner(source);
    var tokens = scanner.scanTokens();

    // For now, just print the tokens.
    for (var token in tokens) {
      print(token);
    }
  }

  static void error(int line, String message) {
    report(line, '', message);
  }

  static void report(int line, String where, String message) {
    stderr.write('[line ${line.toString()}] Error$where: $message');
    hadError = true;
  }
}
