// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test case for http://dartbug.com/21079
import 'dart:mirrors';
import "package:expect/expect.dart";

void main() {
  Expect.isTrue(
    reflectClass(MyException).superclass!.reflectedType == FormatException,
  );

  Expect.isTrue(reflectClass(FormatException).reflectedType == FormatException);
}

class MyException extends FormatException {
  MyException() : super("Test") {}
}
