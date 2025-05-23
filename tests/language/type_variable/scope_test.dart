// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type variables referenced from within static members are malformed.

class Foo<T> implements I<T> {
  Foo() {}

  static Foo<T> m(Foo<T> f) {
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_PARAMETER_REFERENCED_BY_STATIC
  // [cfe] Type variables can't be used in static members.
  //                  ^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_PARAMETER_REFERENCED_BY_STATIC
  // [cfe] Type variables can't be used in static members.
    Foo<T> x = new Foo<String>();
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_PARAMETER_REFERENCED_BY_STATIC
    // [cfe] Type variables can't be used in static members.
    //         ^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    return new Foo<String>();
    //     ^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  }

  // T is in scope for a factory method.
  factory Foo.I(Foo<T> f) {
    Foo<T> x = f;
    return f;
  }

  // T is not in scope for a static field.
  static late Foo<T> f1;
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_PARAMETER_REFERENCED_BY_STATIC
  // [cfe] Type variables can't be used in static members.

  static Foo<T> get f {
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_PARAMETER_REFERENCED_BY_STATIC
  // [cfe] Type variables can't be used in static members.
    return new Foo<String>();
    //     ^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  }

  static void set f(Foo<T> value) {}
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_PARAMETER_REFERENCED_BY_STATIC
  // [cfe] Type variables can't be used in static members.
}

abstract class I<T> {
  factory I(Foo<T> f) = Foo<T>.I;
}

main() {
  Foo.m(new Foo<String>());
  //    ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  new I(new Foo<String>());
  Foo.f1 = new Foo<String>();
  //       ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  var x = Foo.f;
  Foo.f = x;
}
