// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Errors involving dot shorthands of constructors.

// SharedOptions=--enable-experiment=dot-shorthands

import '../dot_shorthand_helper.dart';

void main() {
  // Using a constructor shorthand without any context.

  var ctorNew = .new();
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const ctorConstNew = .new();
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  var ctorNamed = .regular();
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const ctorConstNamed = .regular();
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  UnnamedConstructor Function() ctorTearoff = .new;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
