// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/analyzer_public_api.dart';

/// Suffix indicating the nullability of a type.
///
/// This enum describes whether a `?` or `*` would be used at the end of the
/// canonical representation of a type.  It's subtly different the notions of
/// "nullable", "non-nullable", "potentially nullable", and "potentially
/// non-nullable" defined by the spec.  For example, the type `Null` is
/// nullable, even though it lacks a trailing `?`.
///
/// This enum is exposed through the analyzer API, so it should not be modified
/// without considering the impact on analyzer clients.
@AnalyzerPublicApi(
  message: 'exported by package:analyzer/dart/element/nullability_suffix.dart',
)
enum NullabilitySuffix {
  /// An indication that the canonical representation of the type under
  /// consideration ends with `?`.  Types having this nullability suffix should
  /// be interpreted as being unioned with the Null type.
  question,

  /// An indication that the canonical representation of the type under
  /// consideration ends with `*`.  Types having this nullability suffix are
  /// called "legacy types"; it has not yet been determined whether they should
  /// be unioned with the Null type.
  star,

  /// An indication that the canonical representation of the type under
  /// consideration does not end with either `?` or `*`.
  none,
}
