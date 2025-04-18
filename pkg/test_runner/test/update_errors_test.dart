// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: unnecessary_string_escapes

import 'dart:math' as math;

import 'package:expect/expect.dart';
import 'package:test_runner/src/static_error.dart';
import 'package:test_runner/src/update_errors.dart';

import 'utils.dart';

// Note: This test file validates how some of the special markers used by the
// test runner are parsed. But this test is also run *by* that same test
// runner, and we don't want it to see the markers inside the string literals
// here as significant, so we obfuscate them using seemingly-pointless string
// escapes here like `\/`.

void main() {
  // Inserts single-front end errors.
  expectUpdate("""
int i = "bad";

int another = "wrong";

int third = "boo";
""", errors: [
    makeError(line: 1, column: 9, length: 5, analyzerError: "some.error"),
    makeError(line: 3, column: 15, length: 7, cfeError: "Bad."),
    makeError(line: 5, column: 13, length: 5, webError: "Web.\nError."),
  ], expected: """
int i = "bad";
/\/      ^^^^^
/\/ [analyzer] some.error

int another = "wrong";
/\/            ^^^^^^^
/\/ [cfe] Bad.

int third = "boo";
/\/          ^^^^^
/\/ [web] Web.
/\/ Error.
""");

  // Inserts errors for multiple front ends.
  expectUpdate("""
int i = "bad";

int another = "wrong";

int third = "boo";

int last = "oops";
""", errors: [
    makeError(line: 1, column: 9, length: 5, analyzerError: "some.error"),
    makeError(line: 1, column: 9, length: 5, cfeError: "Bad."),
    makeError(line: 3, column: 15, length: 7, cfeError: "Another bad."),
    makeError(line: 3, column: 15, length: 7, webError: "Web.\nError."),
    makeError(line: 5, column: 13, length: 5, analyzerError: "third.error"),
    makeError(line: 5, column: 13, length: 5, webError: "Web error."),
    makeError(line: 7, column: 12, length: 6, analyzerError: "last.error"),
    makeError(line: 7, column: 12, length: 6, cfeError: "Final.\nError."),
    makeError(line: 7, column: 12, length: 6, webError: "Web error."),
  ], expected: """
int i = "bad";
/\/      ^^^^^
/\/ [analyzer] some.error
/\/ [cfe] Bad.

int another = "wrong";
/\/            ^^^^^^^
/\/ [cfe] Another bad.
/\/ [web] Web.
/\/ Error.

int third = "boo";
/\/          ^^^^^
/\/ [analyzer] third.error
/\/ [web] Web error.

int last = "oops";
/\/         ^^^^^^
/\/ [analyzer] last.error
/\/ [cfe] Final.
/\/ Error.
/\/ [web] Web error.
""");

  // Removes only analyzer errors.
  expectUpdate("""
int i = "bad";
/\/      ^^^^^
/\/ [analyzer] some.error

int another = "wrong";
/\/            ^^^^^^^
/\/ [cfe] Bad.

int third = "boo";
/\/          ^^^^^
/\/ [analyzer] an.error
/\/ [cfe] Wrong.
""", remove: {ErrorSource.analyzer}, expected: """
int i = "bad";

int another = "wrong";
/\/            ^^^^^^^
/\/ [cfe] Bad.

int third = "boo";
/\/          ^^^^^
/\/ [cfe] Wrong.
""");

  // Removes only CFE errors.
  expectUpdate("""
int i = "bad";
/\/      ^^^^^
/\/ [analyzer] some.error

int another = "wrong";
/\/            ^^^^^^^
/\/ [cfe] Bad.

int third = "boo";
/\/          ^^^^^
/\/ [analyzer] an.error
/\/ [cfe] Wrong.
""", remove: {ErrorSource.cfe}, expected: """
int i = "bad";
/\/      ^^^^^
/\/ [analyzer] some.error

int another = "wrong";

int third = "boo";
/\/          ^^^^^
/\/ [analyzer] an.error
""");

  // Removes only web errors.
  expectUpdate("""
int i = "bad";
/\/      ^^^^^
/\/ [analyzer] some.error

int another = "wrong";
/\/            ^^^^^^^
/\/ [web] Bad.

int third = "boo";
/\/          ^^^^^
/\/ [cfe] Error.
/\/ [web] Wrong.
""", remove: {ErrorSource.web}, expected: """
int i = "bad";
/\/      ^^^^^
/\/ [analyzer] some.error

int another = "wrong";

int third = "boo";
/\/          ^^^^^
/\/ [cfe] Error.
""");

  // Removes multiple error sources.
  expectUpdate("""
int i = "bad";
/\/      ^^^^^
/\/ [analyzer] some.error
/\/ [cfe] CFE error.

int another = "wrong";
/\/            ^^^^^^^
/\/ [web] Bad.

int third = "boo";
/\/          ^^^^^
/\/ [analyzer] another.error
/\/ [cfe] Error.
/\/ [web] Wrong.
""", remove: {ErrorSource.analyzer, ErrorSource.web}, expected: """
int i = "bad";
/\/      ^^^^^
/\/ [cfe] CFE error.

int another = "wrong";

int third = "boo";
/\/          ^^^^^
/\/ [cfe] Error.
""");

  // Preserves previous error's indentation if possible.
  expectUpdate("""
int i = "bad";
    /\/    ^^
    /\/ [analyzer] previous.error
""", errors: [
    makeError(line: 1, column: 9, length: 5, analyzerError: "updated.error"),
    makeError(
        line: 1, column: 9, length: 5, cfeError: "Long.\nError.\nMessage."),
  ], expected: """
int i = "bad";
    /\/  ^^^^^
    /\/ [analyzer] updated.error
    /\/ [cfe] Long.
    /\/ Error.
    /\/ Message.
""");

  // Uses previous line's indentation if there was no existing error
  // expectation.
  expectUpdate("""
main() {
  int i = "bad";
}
""", errors: [
    makeError(line: 2, column: 11, length: 5, analyzerError: "updated.error"),
  ], expected: """
main() {
  int i = "bad";
  /\/      ^^^^^
  /\/ [analyzer] updated.error
}
""");

  // Discards previous error indentation if it would collide with carets.
  expectUpdate("""
// This fits:
int i = "bad";
      /\/    ^^
      /\/ [analyzer] previous.error

// This does not:
int j = "bad";
       /\/    ^^
       /\/ [analyzer] previous.error
""", errors: [
    makeError(line: 2, column: 9, length: 5, cfeError: "Error."),
    makeError(line: 7, column: 9, length: 5, cfeError: "Error."),
  ], expected: """
// This fits:
int i = "bad";
      /\/^^^^^
      /\/ [cfe] Error.

// This does not:
int j = "bad";
/\/      ^^^^^
/\/ [cfe] Error.
""");

  // Uses explicit location if indenting based on preceding code would collide
  // with carets.
  expectUpdate("""
main() {
  ["bad"];
}
""", errors: [
    makeError(line: 2, column: 4, length: 5, cfeError: "Error."),
  ], expected: """
main() {
  ["bad"];
  /\/ [error column 4, length 5]
  /\/ [cfe] Error.
}
""");

  // Uses length one if there's no length.
  expectUpdate("""
int i = "bad";
""", errors: [makeError(line: 1, column: 9, cfeError: "Error.")], expected: """
int i = "bad";
/\/      ^
/\/ [cfe] Error.
""");

  // Explicit error location handles null length.
  expectUpdate("""
int i =
"bad";
""", errors: [makeError(line: 2, column: 1, cfeError: "Error.")], expected: """
int i =
"bad";
/\/ [error column 1]
/\/ [cfe] Error.
""");

  // Handles shifted line numbers in explicit error locations.
  // Note that the reported line is line 6, but the output is line 3 to take
  // into account the three removed lines.
  expectUpdate("""
main() {
/\/ ^^
/\/ [analyzer] ERROR.CODE
/\/ [cfe] Error.
}
Error here;
""", errors: [
    makeError(line: 6, column: 1, length: 5, analyzerError: "NEW.ERROR"),
    makeError(line: 6, column: 2, length: 3, cfeError: "Error."),
  ], expected: """
main() {
}
Error here;
/\/ [error column 1, length 5]
/\/ [analyzer] NEW.ERROR
/\/ [error column 2, length 3]
/\/ [cfe] Error.
""");

  // Inserts a blank line if a subsequent line comment would become part of the
  // error message.
  expectUpdate("""
int i = "bad";
// Line comment.
""", errors: [
    makeError(line: 1, column: 9, length: 5, cfeError: "Wrong."),
  ], expected: """
int i = "bad";
/\/      ^^^^^
/\/ [cfe] Wrong.

// Line comment.
""");

  // Inserts a blank line if a subsequent line comment would become part of the
  // error message.
  expectUpdate("""
int i = "bad";
// Line comment.
""", errors: [
    makeError(line: 1, column: 9, length: 5, analyzerError: "ERR.CODE"),
  ], expected: """
int i = "bad";
/\/      ^^^^^
/\/ [analyzer] ERR.CODE

// Line comment.
""");

  // Multiple errors on the same line are ordered by column then length.
  expectUpdate("""
someBadCode();
""", errors: [
    makeError(line: 1, column: 9, length: 5, cfeError: "Wrong 1."),
    makeError(line: 1, column: 9, length: 4, cfeError: "Wrong 2."),
    makeError(line: 1, column: 6, length: 3, cfeError: "Wrong 3."),
    makeError(line: 1, column: 5, length: 5, cfeError: "Wrong 4."),
  ], expected: """
someBadCode();
/\/  ^^^^^
/\/ [cfe] Wrong 4.
/\/   ^^^
/\/ [cfe] Wrong 3.
/\/      ^^^^
/\/ [cfe] Wrong 2.
/\/      ^^^^^
/\/ [cfe] Wrong 1.
""");

  // Shared locations between errors with and without length.
  expectUpdate("""
someBadCode(arg);

moreBadCode(arg);
""", errors: [
    makeError(line: 1, column: 13, length: 3, analyzerError: "Error.CODE"),
    makeError(line: 1, column: 13, cfeError: "Wrong 1."),
    makeError(line: 3, column: 13, cfeError: "Wrong 2."),
    makeError(line: 3, column: 13, length: 3, webError: "Web error."),
  ], expected: """
someBadCode(arg);
/\/          ^^^
/\/ [analyzer] Error.CODE
/\/ [cfe] Wrong 1.

moreBadCode(arg);
/\/          ^^^
/\/ [web] Web error.
/\/ [cfe] Wrong 2.
""");

  // Doesn't crash with RangeError.
  expectUpdate("""
x
// [error line 1, column 1, length 0]
// [cfe] Whatever""", errors: [
    makeError(line: 1, column: 1, length: 0, cfeError: "Foo"),
  ], expected: """
x
// [error column 1]
// [cfe] Foo""");

  contextMessages();
  regression();
}

void contextMessages() {
  // Inserts context messages.
  expectUpdate(
      """
int i = "bad";

int another = "wrong";

int third = "boo";
""",
      errors: [
        makeError(
            line: 3,
            column: 15,
            length: 7,
            analyzerError: "some.error",
            context: [
              makeError(
                  line: 1,
                  column: 9,
                  length: 5,
                  contextError: "Analyzer context."),
              makeError(
                  line: 5,
                  column: 13,
                  length: 5,
                  contextError: "More context."),
            ]),
        makeError(
            line: 3,
            column: 15,
            length: 7,
            cfeError: "CFE error.",
            context: [
              makeError(
                  line: 1, column: 9, length: 5, contextError: "CFE context."),
            ]),
      ],
      remove: {ErrorSource.analyzer},
      includeContext: true,
      expected: """
int i = "bad";
/\/      ^^^^^
/\/ [context 1] Analyzer context.
/\/ [context 2] CFE context.

int another = "wrong";
/\/            ^^^^^^^
/\/ [analyzer 1] some.error
/\/ [cfe 2] CFE error.

int third = "boo";
/\/          ^^^^^
/\/ [context 1] More context.
""");

  // Removes context messages for removed errors.
  expectUpdate(
      """
int i = "bad";
/\/      ^^^^^
/\/ [context 1] Analyzer context.
/\/ [context 2] CFE context.

int another = "wrong";
/\/            ^^^^^^^
/\/ [analyzer 1] some.error
/\/ [cfe 2] CFE error.

int third = "boo";
/\/          ^^^^^
/\/ [context 1] More context.
""",
      remove: {ErrorSource.analyzer},
      includeContext: true,
      expected: """
int i = "bad";
/\/      ^^^^^
/\/ [context 1] CFE context.

int another = "wrong";
/\/            ^^^^^^^
/\/ [cfe 1] CFE error.

int third = "boo";
""");

  // Discards context messages when not told to include them.
  expectUpdate(
      """
int i = "bad";

int another = "wrong";

int third = "boo";
""",
      errors: [
        makeError(
            line: 3,
            column: 15,
            length: 7,
            analyzerError: "some.error",
            context: [
              makeError(
                  line: 1,
                  column: 9,
                  length: 5,
                  contextError: "Analyzer context."),
              makeError(
                  line: 5,
                  column: 13,
                  length: 5,
                  contextError: "More context."),
            ]),
        makeError(
            line: 3,
            column: 15,
            length: 7,
            cfeError: "CFE error.",
            context: [
              makeError(
                  line: 1, column: 9, length: 5, contextError: "CFE context."),
            ]),
      ],
      includeContext: false,
      expected: """
int i = "bad";

int another = "wrong";
/\/            ^^^^^^^
/\/ [analyzer] some.error
/\/ [cfe] CFE error.

int third = "boo";
""");

  // Discards existing context messages when not told to include them.
  expectUpdate(
      """
int i = "bad";
/\/      ^^^^^
/\/ [context 1] CFE context.

int another = "wrong";
/\/            ^^^^^^^
/\/ [cfe 1] CFE error.

int third = "boo";
""",
      errors: [
        makeError(
            line: 5,
            column: 15,
            length: 7,
            analyzerError: "some.error",
            context: [
              makeError(
                  line: 1,
                  column: 9,
                  length: 5,
                  contextError: "Analyzer context."),
              makeError(
                  line: 7,
                  column: 13,
                  length: 5,
                  contextError: "More context."),
            ]),
      ],
      remove: {ErrorSource.analyzer},
      includeContext: false,
      expected: """
int i = "bad";

int another = "wrong";
/\/            ^^^^^^^
/\/ [analyzer] some.error
/\/ [cfe] CFE error.

int third = "boo";
""");
}

void regression() {
  // https://github.com/dart-lang/sdk/issues/37990.
  expectUpdate("""
int get xx => 3;
int get yy => 3;

class A {
  void test() {
    xx = 1;
/\/  ^^^^^^^^^^^^^^
/\/ [cfe] unspecified
/\/  ^^^^^^^^^^^^^^
/\/ [analyzer] unspecified


    yy(4);
/\/  ^^^^^^^^^^^^^^
/\/ [cfe] unspecified
/\/  ^^^^^^^^^^^^^^
/\/ [analyzer] unspecified

  }
}
""", remove: {
    ErrorSource.cfe
  }, errors: [
    makeError(
        line: 6, column: 5, length: 14, cfeError: "Setter not found: 'xx'."),
    makeError(
        line: 16,
        column: 7,
        cfeError: "The method 'call' isn't defined for the class 'int'.")
  ], expected: """
int get xx => 3;
int get yy => 3;

class A {
  void test() {
    xx = 1;
/\/  ^^^^^^^^^^^^^^
/\/ [analyzer] unspecified
/\/ [cfe] Setter not found: 'xx'.


    yy(4);
/\/  ^^^^^^^^^^^^^^
/\/ [analyzer] unspecified
/\/    ^
/\/ [cfe] The method 'call' isn't defined for the class 'int'.

  }
}
""");
}

void expectUpdate(String original,
    {List<StaticError>? errors,
    Set<ErrorSource>? remove,
    bool? includeContext,
    String? expected}) {
  errors ??= const [];
  remove ??= ErrorSource.all.toSet();
  includeContext ??= false;

  var actual = updateErrorExpectations('some_test.dart', original, errors,
      remove: remove, includeContext: includeContext);
  if (actual != expected) {
    // Not using Expect.equals() because the diffs it shows aren't helpful for
    // strings this large.
    var actualLines = actual.split("\n");
    var expectedLines = expected!.split("\n");

    // Figure out which leading lines do match so we can ignore those and
    // highlight the offending ones.
    var matchingActual = <int>{};
    var matchingExpected = <int>{};
    for (var i = 0;
        i < math.min(actualLines.length, expectedLines.length);
        i++) {
      if (actualLines[i] != expectedLines[i]) break;
      matchingActual.add(i);
      matchingExpected.add(i);
    }

    // Find which trailing lines are the same so we can hide those too.
    for (var i = 0;
        i < math.min(actualLines.length, expectedLines.length);
        i++) {
      // Count backwards from the ends of each list.
      var actualIndex = actualLines.length - i - 1;
      var expectedIndex = expectedLines.length - i - 1;
      if (actualLines[actualIndex] != expectedLines[expectedIndex]) break;
      matchingActual.add(actualIndex);
      matchingExpected.add(expectedIndex);
    }

    var buffer = StringBuffer();
    void writeLine(int index, String line, Set<int> matchingLines) {
      // Only show the line if it was different from the expectation.
      if (matchingLines.contains(index)) {
        buffer.writeln("    : $line");
      } else {
        buffer.writeln("${(index + 1).toString().padLeft(4)}: $line");
      }
    }

    buffer.writeln("Output did not match expectation. Expected:");
    for (var i = 0; i < expectedLines.length; i++) {
      writeLine(i, expectedLines[i], matchingExpected);
    }

    buffer.writeln();
    buffer.writeln("Was:");
    for (var i = 0; i < actualLines.length; i++) {
      writeLine(i, actualLines[i], matchingActual);
    }

    Expect.fail(buffer.toString());
  }
}
