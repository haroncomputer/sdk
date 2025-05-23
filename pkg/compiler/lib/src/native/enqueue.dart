// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/elements.dart' show CommonElements, ElementEnvironment;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_backend/native_data.dart' show NativeData;
import '../js_emitter/js_emitter.dart' show CodeEmitterTask;
import '../js_emitter/native_emitter.dart';
import '../options.dart';
import '../universe/use.dart' show TypeUse;
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilder, WorldImpactBuilderImpl;
import 'behavior.dart';
import 'resolver.dart' show NativeClassFinder;

abstract class NativeEnqueuer {
  final Set<ClassEntity> _registeredClasses = {};
  final Set<ClassEntity> _unusedClasses = {};

  /// Returns whether native classes are being used.
  bool get hasInstantiatedNativeClasses => _registeredClasses.isNotEmpty;

  /// Log message reported if all native types are used.
  String? _allUsedMessage;

  final CompilerOptions _options;
  final ElementEnvironment _elementEnvironment;
  final DartTypes _dartTypes;
  final CommonElements _commonElements;

  /// Subclasses of [NativeEnqueuerBase] are constructed by the backend.
  NativeEnqueuer(
    this._options,
    this._elementEnvironment,
    this._commonElements,
    this._dartTypes,
  );

  bool get enableLiveTypeAnalysis => _options.enableNativeLiveTypeAnalysis;

  /// Called when a [type] has been instantiated natively.
  void onInstantiatedType(InterfaceType type) {
    if (_unusedClasses.remove(type.element)) {
      _registeredClasses.add(type.element);
    }
  }

  /// Initial entry point to native enqueuer.
  WorldImpact processNativeClasses(Iterable<Uri> libraries);

  /// Register [classes] as natively instantiated in [impactBuilder].
  void _registerTypeUses(
    WorldImpactBuilder impactBuilder,
    Set<ClassEntity> classes /*, cause*/,
  ) {
    for (ClassEntity cls in classes) {
      if (!_unusedClasses.contains(cls)) {
        // No need to add [classElement] to [impactBuilder]: it has already been
        // instantiated and we don't track origins of native instantiations
        // precisely.
        continue;
      }
      impactBuilder.registerTypeUse(
        TypeUse.nativeInstantiation(_elementEnvironment.getRawType(cls)),
      );
    }
  }

  /// Registers the [nativeBehavior]. Adds the liveness of its instantiated
  /// types to the world.
  void registerNativeBehavior(
    WorldImpactBuilder impactBuilder,
    NativeBehavior nativeBehavior,
    Object cause,
  ) {
    _processNativeBehavior(impactBuilder, nativeBehavior, cause);
  }

  void _processNativeBehavior(
    WorldImpactBuilder impactBuilder,
    NativeBehavior behavior,
    Object cause,
  ) {
    void registerInstantiation(InterfaceType type) {
      impactBuilder.registerTypeUse(TypeUse.nativeInstantiation(type));
    }

    int unusedBefore = _unusedClasses.length;
    Set<ClassEntity> matchingClasses = {};
    for (var type in behavior.typesInstantiated) {
      if (type is SpecialType) {
        if (type == SpecialType.jsObject) {
          registerInstantiation(_commonElements.objectType);
        }
        continue;
      }
      if (type is InterfaceType) {
        if (type == _commonElements.numType) {
          registerInstantiation(_commonElements.doubleType);
          registerInstantiation(_commonElements.intType);
        } else if (type == _commonElements.intType ||
            type == _commonElements.doubleType ||
            type == _commonElements.stringType ||
            type == _commonElements.nullType ||
            type == _commonElements.boolType ||
            type.element == _commonElements.jsJavaScriptBigIntClass ||
            type.element == _commonElements.jsJavaScriptSymbolClass ||
            type == _commonElements.jsJavaScriptObjectType ||
            _dartTypes.isSubtype(
              type,
              _elementEnvironment.getRawType(_commonElements.jsArrayClass),
            )) {
          registerInstantiation(type);
        } else if (_dartTypes.isSubtype(
          type,
          _elementEnvironment.getRawType(
            _commonElements.jsLegacyJavaScriptObjectClass,
          ),
        )) {
          registerInstantiation(type);
          matchingClasses.add(type.element);
        }
        // TODO(johnniwinther): Improve spec string precision to handle type
        // arguments and implements relations that preserve generics. Currently
        // we cannot distinguish between `List`, `List<dynamic>`, and
        // `List<int>` and take all to mean `List<E>`; in effect not including
        // any native subclasses of generic classes.
        // TODO(johnniwinther,sra): Find and replace uses of `List` with the
        // actual implementation classes such as `JSArray` et al.
        matchingClasses.addAll(
          _findUnusedClassesMatching((ClassEntity nativeClass) {
            InterfaceType nativeType = _elementEnvironment.getRawType(
              nativeClass,
            );
            InterfaceType specType = _elementEnvironment.getRawType(
              type.element,
            );
            return _dartTypes.isSubtype(nativeType, specType);
          }),
        );
      } else if (type is DynamicType) {
        matchingClasses.addAll(_unusedClasses);
      } else {
        assert(type is VoidType, '$type was ${type.runtimeType}');
      }
    }
    if (matchingClasses.isNotEmpty && _registeredClasses.isEmpty) {
      matchingClasses.addAll(_onFirstNativeClass(impactBuilder));
    }
    _registerTypeUses(impactBuilder, matchingClasses /*, cause*/);

    // Give an info so that library developers can compile with -v to find why
    // all the native classes are included.
    if (unusedBefore > 0 && unusedBefore == matchingClasses.length) {
      _allUsedMessage ??= 'All native types marked as used due to $cause.';
    }
  }

  Iterable<ClassEntity> _findUnusedClassesMatching(
    bool Function(ClassEntity classElement) predicate,
  ) {
    return _unusedClasses.where(predicate);
  }

  Iterable<ClassEntity> _onFirstNativeClass(WorldImpactBuilder impactBuilder) {
    return _findNativeExceptions();
  }

  Iterable<ClassEntity> _findNativeExceptions() {
    return _findUnusedClassesMatching((ClassEntity classElement) {
      // TODO(sra): Annotate exception classes in dart:html.
      String name = classElement.name;
      if (name.contains('Exception')) return true;
      if (name.contains('Error')) return true;
      return false;
    });
  }

  /// Emits a summary information using the [log] function.
  void logSummary(void Function(String message) log) {
    if (_allUsedMessage != null) {
      log(_allUsedMessage!);
    }
  }
}

class NativeResolutionEnqueuer extends NativeEnqueuer {
  final NativeClassFinder _nativeClassFinder;

  /// The set of all native classes.  Each native class is in [nativeClasses]
  /// and exactly one of [unusedClasses] and [registeredClasses].
  final Set<ClassEntity> _nativeClasses = {};

  NativeResolutionEnqueuer(
    super.options,
    super.elementEnvironment,
    super.commonElements,
    super.dartTypes,
    this._nativeClassFinder,
  );

  Iterable<ClassEntity> get nativeClassesForTesting => _nativeClasses;

  Iterable<ClassEntity> get registeredClassesForTesting => _registeredClasses;

  Iterable<ClassEntity> get liveNativeClasses => _registeredClasses;

  @override
  WorldImpact processNativeClasses(Iterable<Uri> libraries) {
    WorldImpactBuilderImpl impactBuilder = WorldImpactBuilderImpl();
    Iterable<ClassEntity> nativeClasses = _nativeClassFinder
        .computeNativeClasses(libraries);
    _nativeClasses.addAll(nativeClasses);
    _unusedClasses.addAll(nativeClasses);
    if (!enableLiveTypeAnalysis) {
      _registerTypeUses(impactBuilder, _nativeClasses /*, 'forced'*/);
    }
    return impactBuilder;
  }

  @override
  void logSummary(void Function(String message) log) {
    super.logSummary(log);
    log(
      'Resolved ${_registeredClasses.length} native elements used, '
      '${_unusedClasses.length} native elements dead.',
    );
  }
}

class NativeCodegenEnqueuer extends NativeEnqueuer {
  final CodeEmitterTask _emitter;
  final Set<ClassEntity> _nativeClasses;
  final NativeData _nativeData;

  final Set<ClassEntity> _doneAddSubtypes = {};

  NativeCodegenEnqueuer(
    super.options,
    super.elementEnvironment,
    super.commonElements,
    super.dartTypes,
    this._emitter,
    this._nativeClasses,
    this._nativeData,
  );

  @override
  WorldImpact processNativeClasses(Iterable<Uri> libraries) {
    WorldImpactBuilderImpl impactBuilder = WorldImpactBuilderImpl();
    _unusedClasses.addAll(_nativeClasses);

    if (!enableLiveTypeAnalysis) {
      _registerTypeUses(impactBuilder, _nativeClasses /*, 'forced'*/);
    }

    // TODO: this code is a bit of a hack to add all the resolved classes.
    Set<ClassEntity> matchingClasses = {};
    for (ClassEntity classElement in _nativeClasses) {
      if (_unusedClasses.contains(classElement)) {
        matchingClasses.add(classElement);
      }
    }
    if (matchingClasses.isNotEmpty && _registeredClasses.isEmpty) {
      matchingClasses.addAll(_onFirstNativeClass(impactBuilder));
    }
    _registerTypeUses(impactBuilder, matchingClasses /*, 'was resolved'*/);
    return impactBuilder;
  }

  @override
  void _registerTypeUses(
    WorldImpactBuilder impactBuilder,
    Set<ClassEntity> classes /*, cause*/,
  ) {
    super._registerTypeUses(impactBuilder, classes /*, cause*/);

    for (ClassEntity classElement in classes) {
      // Add the information that this class is a subtype of its supertypes. The
      // code emitter and the ssa builder use that information.
      _addSubtypes(classElement, _emitter.nativeEmitter);
    }
  }

  void _addSubtypes(ClassEntity cls, NativeEmitter emitter) {
    if (!_nativeData.isNativeClass(cls)) return;
    if (_doneAddSubtypes.contains(cls)) return;
    _doneAddSubtypes.add(cls);

    // Walk the superclass chain since classes on the superclass chain might not
    // be instantiated (abstract or simply unused).
    // Note: here and below we expect the superclass always to be non-null
    // because we always start from a native class, which at least has Object as
    // a superclass.
    ClassEntity superclass = _elementEnvironment.getSuperClass(cls)!;
    _addSubtypes(superclass, emitter);

    _elementEnvironment.forEachSupertype(cls, (InterfaceType type) {
      List<ClassEntity> subtypes = emitter.subtypes[type.element] ??=
          <ClassEntity>[];
      subtypes.add(cls);
    });

    // Skip through all the mixin applications in the super class
    // chain. That way, the direct subtypes set only contain the
    // natives classes.
    while (_elementEnvironment.isMixinApplication(superclass)) {
      assert(!_nativeData.isNativeClass(superclass));
      superclass = _elementEnvironment.getSuperClass(superclass)!;
    }

    List<ClassEntity> directSubtypes = emitter.directSubtypes[superclass] ??=
        <ClassEntity>[];
    directSubtypes.add(cls);
  }

  @override
  void logSummary(void Function(String message) log) {
    super.logSummary(log);
    log(
      'Compiled ${_registeredClasses.length} native classes, '
      '${_unusedClasses.length} native classes omitted.',
    );
  }
}
