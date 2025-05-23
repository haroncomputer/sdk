// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/resource_provider_mixin.dart';

abstract class EmbedderRelatedTest with ResourceProviderMixin {
  final String emptyPath = '/home/.pub-cache/empty';
  final String foxPath = '/home/.pub-cache/fox';
  final String foxLib = '/home/.pub-cache/fox/lib';

  void setUp() {
    newFolder('/home/.pub-cache/empty');
    newFolder('/home/.pub-cache/fox/lib');
    newFile('/home/.pub-cache/fox/lib/_embedder.yaml', r'''
embedded_libs:
  "dart:deep": "deep/directory/file.dart"
  "dart:core" : "core/core.dart"
  "dart:fox": "slippy.dart"
  "dart:bear": "grizzly.dart"
  "dart:relative": "../relative.dart"
  "fart:loudly": "nomatter.dart"
''');
  }
}
