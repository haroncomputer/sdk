// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.new_instance_with_type_arguments_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class A<T> {
  Type get t => T;
}

class B extends A<int> {}

class C<S> extends A<num> {
  Type get s => S;
}

main() {
  ClassMirror cmA = reflectClass(A);
  ClassMirror cmB = reflectClass(B);
  ClassMirror cmC = reflectClass(C);

  dynamic a_int = new A<int>();
  dynamic a_dynamic = new A();
  dynamic b = new B();
  dynamic c_string = new C<String>();
  dynamic c_dynamic = new C();

  Expect.equals(int, a_int.t);
  Expect.equals(dynamic, a_dynamic.t);
  Expect.equals(int, b.t);
  Expect.equals(num, c_string.t);
  Expect.equals(num, c_dynamic.t);

  Expect.equals(String, c_string.s);
  Expect.equals(dynamic, c_dynamic.s);

  dynamic reflective_a_int = cmB.superclass!
      .newInstance(Symbol.empty, [])
      .reflectee;
  dynamic reflective_a_dynamic = cmA.newInstance(Symbol.empty, []).reflectee;
  dynamic reflective_b = cmB.newInstance(Symbol.empty, []).reflectee;
  dynamic reflective_c_dynamic = cmC.newInstance(Symbol.empty, []).reflectee;

  Expect.equals(int, reflective_a_int.t);
  Expect.equals(dynamic, reflective_a_dynamic.t);
  Expect.equals(int, reflective_b.t);
  Expect.equals(num, c_string.t);
  Expect.equals(num, reflective_c_dynamic.t);

  Expect.equals(String, c_string.s);
  Expect.equals(dynamic, reflective_c_dynamic.s);

  Expect.equals(a_int.runtimeType, reflective_a_int.runtimeType);
  Expect.equals(a_dynamic.runtimeType, reflective_a_dynamic.runtimeType);
  Expect.equals(b.runtimeType, reflective_b.runtimeType);
  Expect.equals(c_dynamic.runtimeType, reflective_c_dynamic.runtimeType);
}
