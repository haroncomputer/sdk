// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' show Component, Library;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/target/changed_structure_notifier.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/transformations/track_widget_constructor_locations.dart';
import 'package:vm/modular/target/vm.dart' show VmTarget;

class FlutterTarget extends VmTarget {
  FlutterTarget(TargetFlags flags) : super(flags);

  late final WidgetCreatorTracker _widgetTracker = WidgetCreatorTracker();

  @override
  String get name => 'flutter';

  // This is the order that bootstrap libraries are loaded according to
  // `runtime/vm/object_store.h`.
  @override
  List<String> get extraRequiredLibraries => const <String>[
    'dart:async',
    'dart:collection',
    'dart:concurrent',
    'dart:convert',
    'dart:developer',
    'dart:ffi',
    'dart:_internal',
    'dart:isolate',
    'dart:math',

    // The library dart:mirrors may be ignored by the VM, e.g. when built in
    // PRODUCT mode.
    'dart:mirrors',

    'dart:typed_data',
    'dart:nativewrappers',
    'dart:io',

    // Required for flutter.
    'dart:ui',
    'dart:vmservice_io',
  ];

  @override
  List<String> get extraRequiredLibrariesPlatform => const <String>[];

  @override
  DartLibrarySupport get dartLibrarySupport =>
      const CustomizedDartLibrarySupport(unsupported: {'mirrors'});

  @override
  void performPreConstantEvaluationTransformations(
    Component component,
    CoreTypes coreTypes,
    List<Library> libraries,
    DiagnosticReporter diagnosticReporter, {
    void Function(String msg)? logger,
    ChangedStructureNotifier? changedStructureNotifier,
  }) {
    super.performPreConstantEvaluationTransformations(
      component,
      coreTypes,
      libraries,
      diagnosticReporter,
      logger: logger,
      changedStructureNotifier: changedStructureNotifier,
    );
    if (flags.trackWidgetCreation) {
      _widgetTracker.transform(component, libraries, changedStructureNotifier);
    }
  }
}
