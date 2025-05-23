// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common/elements.dart';
import '../elements/entities.dart' show ClassEntity;
import '../elements/types.dart' show InterfaceType;
import '../js_model/elements.dart';
import '../kernel/element_map.dart' show KernelToElementMap;
import '../serialization/serialization.dart';
import 'class_set.dart';

// TODO(johnniwinther): Move more methods from `JClosedWorld` to
// `ClassHierarchy`.
abstract class ClassHierarchy {
  /// Deserializes a [ClassHierarchy] object from [source].
  factory ClassHierarchy.readFromDataSource(
    DataSourceReader source,
    CommonElements commonElements,
  ) = ClassHierarchyImpl.readFromDataSource;

  /// Serializes this [ClassHierarchy] to [sink].
  void writeToDataSink(DataSinkWriter sink);

  /// Returns `true` if [cls] is either directly or indirectly instantiated.
  bool isInstantiated(ClassEntity cls);

  /// Returns `true` if [cls] is directly instantiated. This means that at
  /// runtime instances of exactly [cls] are assumed to exist.
  bool isDirectlyInstantiated(ClassEntity cls);

  /// Returns `true` if [cls] is abstractly instantiated. This means that at
  /// runtime instances of [cls] or unknown subclasses of [cls] are assumed to
  /// exist.
  ///
  /// This is used to mark native and/or reflectable classes as instantiated.
  /// For native classes we do not know the exact class that instantiates [cls]
  /// so [cls] here represents the root of the subclasses. For reflectable
  /// classes we need event abstract classes to be 'live' even though they
  /// cannot themselves be instantiated.
  bool isAbstractlyInstantiated(ClassEntity cls);

  /// Returns `true` if [cls] is either directly or abstractly instantiated.
  ///
  /// See [isDirectlyInstantiated] and [isAbstractlyInstantiated].
  bool isExplicitlyInstantiated(ClassEntity cls);

  /// Returns `true` if [cls] is indirectly instantiated, that is through a
  /// subclass.
  bool isIndirectlyInstantiated(ClassEntity cls);

  /// Return `true` if [x] is a (non-strict) subclass of [y].
  bool isSubclassOf(ClassEntity x, ClassEntity y);

  /// Returns `true` if [x] is a subtype of [y], that is, if [x] implements an
  /// instance of [y].
  bool isSubtypeOf(ClassEntity x, ClassEntity y);

  /// Returns an iterable over the directly instantiated classes that extend
  /// [cls] possibly including [cls] itself, if it is live.
  Iterable<ClassEntity> subclassesOf(ClassEntity cls);

  /// Returns an iterable over the directly instantiated classes that extend
  /// [cls] _not_ including [cls] itself.
  Iterable<ClassEntity> strictSubclassesOf(ClassEntity cls);

  /// Returns the number of live classes that extend [cls] _not_
  /// including [cls] itself.
  int strictSubclassCount(ClassEntity cls);

  /// Applies [f] to each live class that extend [cls] _not_ including [cls]
  /// itself.
  void forEachStrictSubclassOf(
    ClassEntity cls,
    IterationStep Function(ClassEntity cls) f,
  );

  /// Returns `true` if [predicate] applies to any live class that extend [cls]
  /// _not_ including [cls] itself.
  bool anyStrictSubclassOf(
    ClassEntity cls,
    bool Function(ClassEntity cls) predicate,
  );

  /// Returns an iterable over the directly instantiated that implement [cls]
  /// possibly including [cls] itself, if it is live.
  Iterable<ClassEntity> subtypesOf(ClassEntity cls);

  /// Returns an iterable over the directly instantiated that implement [cls]
  /// _not_ including [cls].
  Iterable<ClassEntity> strictSubtypesOf(ClassEntity cls);

  /// Returns an iterable over all the classes that implement [cls], including
  /// [cls] itself.
  Iterable<ClassEntity> allSubtypesOf(ClassEntity cls);

  /// Returns the number of live classes that implement [cls] _not_
  /// including [cls] itself.
  int strictSubtypeCount(ClassEntity cls);

  /// Applies [f] to each live class that implements [cls] _not_ including [cls]
  /// itself.
  void forEachStrictSubtypeOf(
    ClassEntity cls,
    IterationStep Function(ClassEntity cls) f,
  );

  /// Returns `true` if [predicate] applies to any live class that implements
  /// [cls] _not_ including [cls] itself.
  bool anyStrictSubtypeOf(
    ClassEntity cls,
    bool Function(ClassEntity cls) predicate,
  );

  /// Returns `true` if [a] and [b] have any known common subtypes.
  bool haveAnyCommonSubtypes(ClassEntity a, ClassEntity b);

  /// Returns `true` if any directly instantiated class other than [cls] extends
  /// [cls].
  bool hasAnyStrictSubclass(ClassEntity cls);

  /// Returns `true` if any directly instantiated class other than [cls]
  /// implements [cls].
  bool hasAnyStrictSubtype(ClassEntity cls);

  /// Returns `true` if all directly instantiated classes that implement [cls]
  /// extend it.
  bool hasOnlySubclasses(ClassEntity cls);

  /// Returns a [SubclassResult] for the subclasses that are contained in
  /// the subclass/subtype sets of both [cls1] and [cls2].
  ///
  /// Classes that are implied by included superclasses/supertypes are not
  /// returned.
  ///
  /// For instance for this hierarchy
  ///
  ///     class A {}
  ///     class B {}
  ///     class C implements A, B {}
  ///     class D extends C {}
  ///
  /// the query
  ///
  ///     commonSubclasses(A, ClassQuery.SUBTYPE, B, ClassQuery.SUBTYPE)
  ///
  /// return the set {C} because [D] is implied by [C].
  SubclassResult commonSubclasses(
    ClassEntity cls1,
    ClassQuery query1,
    ClassEntity cls2,
    ClassQuery query2,
  );

  /// Returns [ClassHierarchyNode] for [cls] used to model the class hierarchies
  /// of known classes.
  ///
  /// This method is only provided for testing. For queries on classes, use the
  /// methods defined in [JClosedWorld].
  ClassHierarchyNode getClassHierarchyNode(ClassEntity cls);

  /// Returns [ClassSet] for [cls] used to model the extends and implements
  /// relations of known classes.
  ///
  /// This method is only provided for testing. For queries on classes, use the
  /// methods defined in [JClosedWorld].
  ClassSet getClassSet(ClassEntity cls);

  /// Returns a string representation of the closed world.
  ///
  /// If [cls] is provided, the dump will contain only classes related to [cls].
  String dump([ClassEntity cls]);
}

class ClassHierarchyImpl implements ClassHierarchy {
  /// Tag used for identifying serialized [ClassHierarchy] objects in a
  /// debugging data stream.
  static const String tag = 'class-hierarchy';

  final CommonElements _commonElements;
  final Map<ClassEntity, ClassHierarchyNode> _classHierarchyNodes;
  final Map<ClassEntity, ClassSet> _classSets;

  ClassHierarchyImpl(
    this._commonElements,
    this._classHierarchyNodes,
    this._classSets,
  );

  factory ClassHierarchyImpl.readFromDataSource(
    DataSourceReader source,
    CommonElements commonElements,
  ) {
    source.begin(tag);
    Map<ClassEntity, ClassHierarchyNode> classHierarchyNodes =
        ClassHierarchyNodesMap();
    int classCount = source.readInt();
    for (int i = 0; i < classCount; i++) {
      ClassHierarchyNode node = ClassHierarchyNode.readFromDataSource(
        source,
        classHierarchyNodes,
      );
      classHierarchyNodes[node.cls] = node;
    }
    Map<ClassEntity, ClassSet> classSets = {};
    for (int i = 0; i < classCount; i++) {
      ClassSet classSet = ClassSet.readFromDataSource(
        source,
        classHierarchyNodes,
      );
      classSets[classSet.cls] = classSet;
    }

    source.end(tag);
    return ClassHierarchyImpl(commonElements, classHierarchyNodes, classSets);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeInt(_classSets.length);
    ClassHierarchyNode node = getClassHierarchyNode(
      _commonElements.objectClass,
    );
    node.forEachSubclass((ClassEntity cls) {
      getClassHierarchyNode(cls).writeToDataSink(sink);
      return IterationStep.continue_;
    }, ClassHierarchyNode.all);
    ClassSet set = getClassSet(_commonElements.objectClass);
    set.forEachSubclass((ClassEntity cls) {
      getClassSet(cls).writeToDataSink(sink);
      return IterationStep.continue_;
    }, ClassHierarchyNode.all);
    sink.end(tag);
  }

  @override
  bool isInstantiated(ClassEntity cls) {
    ClassHierarchyNode? node = _classHierarchyNodes[cls];
    return node != null && node.isInstantiated;
  }

  @override
  bool isDirectlyInstantiated(ClassEntity cls) {
    ClassHierarchyNode? node = _classHierarchyNodes[cls];
    return node != null && node.isDirectlyInstantiated;
  }

  @override
  bool isAbstractlyInstantiated(ClassEntity cls) {
    ClassHierarchyNode? node = _classHierarchyNodes[cls];
    return node != null && node.isAbstractlyInstantiated;
  }

  @override
  bool isExplicitlyInstantiated(ClassEntity cls) {
    ClassHierarchyNode? node = _classHierarchyNodes[cls];
    return node != null && node.isExplicitlyInstantiated;
  }

  @override
  bool isIndirectlyInstantiated(ClassEntity cls) {
    ClassHierarchyNode? node = _classHierarchyNodes[cls];
    return node != null && node.isIndirectlyInstantiated;
  }

  @override
  bool isSubtypeOf(ClassEntity x, ClassEntity y) {
    ClassSet classSet =
        _classSets[y] ??
        failedAt(
          y,
          "No ClassSet for $y (${y.runtimeType}): "
          "${dump(y)} : $_classSets",
        );
    ClassHierarchyNode classHierarchyNode =
        _classHierarchyNodes[x] ??
        failedAt(x, "No ClassHierarchyNode for $x: ${dump(x)}");
    return classSet.hasSubtype(classHierarchyNode);
  }

  @override
  bool isSubclassOf(ClassEntity x, ClassEntity y) {
    return _classHierarchyNodes[y]!.hasSubclass(_classHierarchyNodes[x]!);
  }

  @override
  Iterable<ClassEntity> subclassesOf(ClassEntity cls) {
    ClassHierarchyNode? hierarchy = _classHierarchyNodes[cls];
    if (hierarchy == null) return const [];
    return hierarchy.subclassesByMask(
      ClassHierarchyNode.explicitlyInstantiated,
    );
  }

  @override
  Iterable<ClassEntity> strictSubclassesOf(ClassEntity cls) {
    ClassHierarchyNode? subclasses = _classHierarchyNodes[cls];
    if (subclasses == null) return const [];
    return subclasses.subclassesByMask(
      ClassHierarchyNode.explicitlyInstantiated,
      strict: true,
    );
  }

  @override
  int strictSubclassCount(ClassEntity cls) {
    ClassHierarchyNode? subclasses = _classHierarchyNodes[cls];
    if (subclasses == null) return 0;
    return subclasses.instantiatedSubclassCount;
  }

  @override
  void forEachStrictSubclassOf(
    ClassEntity cls,
    IterationStep Function(ClassEntity cls) f,
  ) {
    ClassHierarchyNode? subclasses = _classHierarchyNodes[cls];
    if (subclasses == null) return;
    subclasses.forEachSubclass(
      f,
      ClassHierarchyNode.explicitlyInstantiated,
      strict: true,
    );
  }

  @override
  bool anyStrictSubclassOf(
    ClassEntity cls,
    bool Function(ClassEntity cls) predicate,
  ) {
    ClassHierarchyNode? subclasses = _classHierarchyNodes[cls];
    if (subclasses == null) return false;
    return subclasses.anySubclass(
      predicate,
      ClassHierarchyNode.explicitlyInstantiated,
      strict: true,
    );
  }

  @override
  Iterable<ClassEntity> subtypesOf(ClassEntity cls) {
    ClassSet? classSet = _classSets[cls];
    if (classSet == null) {
      return const [];
    } else {
      return classSet.subtypesByMask(ClassHierarchyNode.explicitlyInstantiated);
    }
  }

  @override
  Iterable<ClassEntity> strictSubtypesOf(ClassEntity cls) {
    ClassSet? classSet = _classSets[cls];
    if (classSet == null) {
      return const [];
    } else {
      return classSet.subtypesByMask(
        ClassHierarchyNode.explicitlyInstantiated,
        strict: true,
      );
    }
  }

  @override
  Iterable<ClassEntity> allSubtypesOf(ClassEntity cls) {
    ClassSet? classSet = _classSets[cls];
    if (classSet == null) {
      return const [];
    } else {
      return classSet.subtypesByMask(ClassHierarchyNode.all);
    }
  }

  @override
  int strictSubtypeCount(ClassEntity cls) {
    ClassSet? classSet = _classSets[cls];
    if (classSet == null) return 0;
    return classSet.instantiatedSubtypeCount;
  }

  @override
  void forEachStrictSubtypeOf(
    ClassEntity cls,
    IterationStep Function(ClassEntity cls) f,
  ) {
    ClassSet? classSet = _classSets[cls];
    if (classSet == null) return;
    classSet.forEachSubtype(
      f,
      ClassHierarchyNode.explicitlyInstantiated,
      strict: true,
    );
  }

  @override
  bool anyStrictSubtypeOf(
    ClassEntity cls,
    bool Function(ClassEntity cls) predicate,
  ) {
    ClassSet? classSet = _classSets[cls];
    if (classSet == null) return false;
    return classSet.anySubtype(
      predicate,
      ClassHierarchyNode.explicitlyInstantiated,
      strict: true,
    );
  }

  @override
  bool haveAnyCommonSubtypes(ClassEntity a, ClassEntity b) {
    ClassSet? classSetA = _classSets[a];
    ClassSet? classSetB = _classSets[b];
    if (classSetA == null || classSetB == null) return false;
    // TODO(johnniwinther): Implement an optimized query on [ClassSet].
    Set<ClassEntity> subtypesOfB = classSetB.subtypes().toSet();
    for (ClassEntity subtypeOfA in classSetA.subtypes()) {
      if (subtypesOfB.contains(subtypeOfA)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool hasAnyStrictSubclass(ClassEntity cls) {
    ClassHierarchyNode? subclasses = _classHierarchyNodes[cls];
    if (subclasses == null) return false;
    return subclasses.isIndirectlyInstantiated;
  }

  @override
  bool hasAnyStrictSubtype(ClassEntity cls) {
    return strictSubtypeCount(cls) > 0;
  }

  @override
  bool hasOnlySubclasses(ClassEntity cls) {
    // TODO(johnniwinther): move this to ClassSet?
    if (cls == _commonElements.objectClass) return true;
    ClassSet? classSet = _classSets[cls];
    if (classSet == null) {
      // Vacuously true.
      return true;
    }
    return classSet.hasOnlyInstantiatedSubclasses;
  }

  @override
  SubclassResult commonSubclasses(
    ClassEntity cls1,
    ClassQuery query1,
    ClassEntity cls2,
    ClassQuery query2,
  ) {
    if (query1 == ClassQuery.exact && query2 == ClassQuery.exact) {
      // Exact classes [cls1] and [cls2] must be identical to have any classes
      // in common.
      if (cls1 != cls2) {
        return SimpleSubclassResult.empty;
      }
      return SimpleSubclassResult.exact1;
    } else if (query1 == ClassQuery.exact) {
      if (query2 == ClassQuery.subclass) {
        // Exact [cls1] must be a subclass of [cls2] to have any classes in
        // common.
        if (isSubclassOf(cls1, cls2)) {
          return SimpleSubclassResult.exact1;
        }
      } else if (query2 == ClassQuery.subtype) {
        // Exact [cls1] must be a subtype of [cls2] to have any classes in
        // common.
        if (isSubtypeOf(cls1, cls2)) {
          return SimpleSubclassResult.exact1;
        }
      }
      return SimpleSubclassResult.empty;
    } else if (query2 == ClassQuery.exact) {
      if (query1 == ClassQuery.subclass) {
        // Exact [cls2] must be a subclass of [cls1] to have any classes in
        // common.
        if (isSubclassOf(cls2, cls1)) {
          return SimpleSubclassResult.exact2;
        }
      } else if (query1 == ClassQuery.subtype) {
        // Exact [cls2] must be a subtype of [cls1] to have any classes in
        // common.
        if (isSubtypeOf(cls2, cls1)) {
          return SimpleSubclassResult.exact2;
        }
      }
      return SimpleSubclassResult.empty;
    } else if (query1 == ClassQuery.subclass && query2 == ClassQuery.subclass) {
      // [cls1] must be a subclass of [cls2] or vice versa to have any classes
      // in common.
      if (cls1 == cls2 || isSubclassOf(cls1, cls2)) {
        // The subclasses of [cls1] are contained within the subclasses of
        // [cls2].
        return SimpleSubclassResult.subclass1;
      } else if (isSubclassOf(cls2, cls1)) {
        // The subclasses of [cls2] are contained within the subclasses of
        // [cls1].
        return SimpleSubclassResult.subclass2;
      }
      return SimpleSubclassResult.empty;
    } else if (query1 == ClassQuery.subclass) {
      if (isSubtypeOf(cls1, cls2)) {
        // The subclasses of [cls1] are all subtypes of [cls2].
        return SimpleSubclassResult.subclass1;
      }
      if (cls1 == _commonElements.objectClass) {
        // Since [cls1] is `Object` all subtypes of [cls2] are contained within
        // the subclasses of [cls1].
        return SimpleSubclassResult.subtype2;
      }
      // Find all the root subclasses of [cls1] of that implement [cls2].
      //
      // For this hierarchy:
      //
      //     class I {}
      //     class A {}
      //     class B extends A implements I {}
      //     class C extends B {}
      //     class D extends A implements I {}
      //
      // the common subclasses of "subclass of A" and "subtype of I" returns
      // "subclasses of {B, D}". The inclusion of class `C` is implied because
      // it is a subclass of `B`.
      List<ClassEntity> classes = [];
      forEachStrictSubclassOf(cls1, (ClassEntity subclass) {
        if (isSubtypeOf(subclass, cls2)) {
          classes.add(subclass);
          // Skip subclasses of [subclass]; they all implement [cls2] by
          // inheritance and are included in the subclasses of [subclass].
          return IterationStep.skipSubclasses;
        }
        return IterationStep.continue_;
      });
      return SetSubclassResult(classes);
    } else if (query2 == ClassQuery.subclass) {
      if (isSubtypeOf(cls2, cls1)) {
        // The subclasses of [cls2] are all subtypes of [cls1].
        return SimpleSubclassResult.subclass2;
      }
      if (cls2 == _commonElements.objectClass) {
        // Since [cls2] is `Object` all subtypes of [cls1] are contained within
        // the subclasses of [cls2].
        return SimpleSubclassResult.subtype1;
      }
      // Find all the root subclasses of [cls2] of that implement [cls1].
      List<ClassEntity> classes = [];
      forEachStrictSubclassOf(cls2, (ClassEntity subclass) {
        if (isSubtypeOf(subclass, cls1)) {
          classes.add(subclass);
          // Skip subclasses of [subclass]; they all implement [cls1] by
          // inheritance and are included in the subclasses of [subclass].
          return IterationStep.skipSubclasses;
        }
        return IterationStep.continue_;
      });
      return SetSubclassResult(classes);
    } else {
      if (cls1 == cls2 || isSubtypeOf(cls1, cls2)) {
        // The subtypes of [cls1] are contained within the subtypes of [cls2].
        return SimpleSubclassResult.subtype1;
      } else if (isSubtypeOf(cls2, cls1)) {
        // The subtypes of [cls2] are contained within the subtypes of [cls1].
        return SimpleSubclassResult.subtype2;
      }
      // Find all the root subclasses of [cls1] of that implement [cls2].
      //
      // For this hierarchy:
      //
      //     class I {}
      //     class A {}
      //     class B extends A implements I {}
      //     class C extends B {}
      //     class D extends A implements I {}
      //     class E implements B {}
      //     class F extends E {}
      //
      // the common subclasses of "subtype of A" and "subtype of I" returns
      // "subclasses of {B, D, E}". The inclusion of classes `C` and `F` is
      // implied because they are subclasses of `B` and `E`, respectively.
      List<ClassEntity> classes = [];
      forEachStrictSubtypeOf(cls1, (ClassEntity subclass) {
        if (isSubtypeOf(subclass, cls2)) {
          classes.add(subclass);
          // Skip subclasses of [subclass]; they all implement [cls2] by
          // inheritance and are included in the subclasses of [subclass].
          return IterationStep.skipSubclasses;
        }
        return IterationStep.continue_;
      });
      return SetSubclassResult(classes);
    }
  }

  @override
  ClassHierarchyNode getClassHierarchyNode(ClassEntity cls) {
    return _classHierarchyNodes[cls]!;
  }

  @override
  ClassSet getClassSet(ClassEntity cls) {
    return _classSets[cls]!;
  }

  @override
  String dump([ClassEntity? cls]) {
    StringBuffer sb = StringBuffer();
    if (cls != null) {
      sb.write("Classes in the closed world related to $cls:\n");
    } else {
      sb.write("Instantiated classes in the closed world:\n");
    }
    getClassHierarchyNode(
      _commonElements.objectClass,
    ).printOn(sb, ' ', instantiatedOnly: cls == null, withRespectTo: cls);
    return sb.toString();
  }
}

class ClassHierarchyBuilder {
  // We keep track of subtype and subclass relationships in four
  // distinct sets to make class hierarchy analysis faster.
  final Map<ClassEntity, ClassHierarchyNode> _classHierarchyNodes = {};
  final Map<ClassEntity, ClassSet> _classSets = {};
  final Map<ClassEntity, Set<ClassEntity>> mixinUses = {};

  final CommonElements _commonElements;
  final KernelToElementMap _elementMap;

  ClassHierarchyBuilder(this._commonElements, this._elementMap);

  ClassHierarchy close() {
    assert(
      _classHierarchyNodes.length == _classSets.length,
      "ClassHierarchyNode/ClassSet mismatch: "
      "$_classHierarchyNodes vs "
      "$_classSets",
    );
    return ClassHierarchyImpl(
      _commonElements,
      _classHierarchyNodes,
      _classSets,
    );
  }

  /// Returns true if [cls] is not extended by any other class and is it not
  /// used as a mixin.
  bool hasNoSubclasses(ClassEntity cls) {
    final classSet = _classSets[cls]!;
    return classSet.node.directSubclasses.isEmpty &&
        classSet.mixinApplicationNodes.isEmpty;
  }

  /// Returns true if [cls] is instantiated either directly, indirectly or
  /// abstractly.
  bool isInstantiated(ClassEntity cls) {
    return _classHierarchyNodes[cls]!.isInstantiated;
  }

  void registerClass(ClassEntity cls) {
    _ensureClassSet(cls);
  }

  ClassHierarchyNode _ensureClassHierarchyNode(ClassEntity cls) {
    return _classHierarchyNodes.putIfAbsent(cls, () {
      cls as JClass; // TODO(48820): Try to remove.
      ClassHierarchyNode? parentNode;
      ClassEntity? superclass = _elementMap.getSuperClass(cls);
      if (superclass != null) {
        parentNode = _ensureClassHierarchyNode(superclass);
      }
      return ClassHierarchyNode(
        parentNode,
        cls,
        _elementMap.getHierarchyDepth(cls),
      );
    });
  }

  ClassSet _ensureClassSet(ClassEntity cls) {
    return _classSets.putIfAbsent(cls, () {
      cls as JClass;
      ClassHierarchyNode node = _ensureClassHierarchyNode(cls);
      ClassSet classSet = ClassSet(node);

      for (InterfaceType type in _elementMap.getSuperTypes(cls)) {
        // TODO(johnniwinther): Optimization: Avoid adding [cls] to
        // superclasses.
        ClassSet subtypeSet = _ensureClassSet(type.element);
        subtypeSet.addSubtype(node);
      }

      ClassEntity? appliedMixin = _elementMap.getAppliedMixin(cls);
      while (appliedMixin != null) {
        // TODO(johnniwinther): Use the data stored in [ClassSet].
        registerMixinUse(cls, appliedMixin);
        ClassSet mixinSet = _ensureClassSet(appliedMixin);
        mixinSet.addMixinApplication(node);

        // In case of
        //
        //    class A {}
        //    class B = Object with A;
        //    class C = Object with B;
        //
        // we need to register that C not only mixes in B but also A.

        // TODO(48820): Can we remove the need for `as IndexedClass`?
        appliedMixin = _elementMap.getAppliedMixin(appliedMixin as JClass);
      }
      return classSet;
    });
  }

  void _updateSuperClassHierarchyNodeForClass(ClassHierarchyNode node) {
    // Ensure that classes implicitly implementing `Function` are in its
    // subtype set.
    final cls = node.cls;
    if (cls != _commonElements.functionClass &&
        _elementMap.implementsFunction(cls as JClass)) {
      ClassSet subtypeSet = _ensureClassSet(_commonElements.functionClass);
      subtypeSet.addSubtype(node);
    }
    if (!node.isInstantiated && node.parentNode != null) {
      _updateSuperClassHierarchyNodeForClass(node.parentNode!);
    }
  }

  void updateClassHierarchyNodeForClass(
    ClassEntity cls, {
    bool directlyInstantiated = false,
    bool abstractlyInstantiated = false,
  }) {
    ClassHierarchyNode node = _ensureClassSet(cls).node;
    _updateSuperClassHierarchyNodeForClass(node);
    if (directlyInstantiated) {
      node.isDirectlyInstantiated = true;
    }
    if (abstractlyInstantiated) {
      node.isAbstractlyInstantiated = true;
    }
  }

  void registerMixinUse(ClassEntity mixinApplication, ClassEntity mixin) {
    // TODO(johnniwinther): Add map restricted to live classes.
    // We don't support patch classes as mixin.
    Set<ClassEntity> users = mixinUses.putIfAbsent(mixin, () => {});
    users.add(mixinApplication);
  }

  bool _isSubtypeOf(ClassEntity x, ClassEntity y) {
    assert(
      _classSets.containsKey(x),
      "ClassSet for $x has not been computed yet.",
    );
    ClassSet classSet =
        _classSets[y] ??
        failedAt(y, "No ClassSet for $y (${y.runtimeType}): $_classSets");
    ClassHierarchyNode classHierarchyNode =
        _classHierarchyNodes[x] ?? failedAt(x, "No ClassHierarchyNode for $x");
    return classSet.hasSubtype(classHierarchyNode);
  }

  /// Returns `true` if a dynamic access on an instance of [exactClass] can
  /// target a member declared in [memberHoldingClass].
  bool isInheritedInExactClass(
    ClassEntity memberHoldingClass,
    ClassEntity exactClass,
  ) {
    ClassHierarchyNode exactClassNode = _classHierarchyNodes[exactClass]!;
    if (!exactClassNode.isAbstractlyInstantiated &&
        !exactClassNode.isDirectlyInstantiated) {
      // No instances of [thisClass] are live.
      return false;
    }
    ClassSet memberHoldingClassSet = _classSets[memberHoldingClass]!;
    if (memberHoldingClassSet.hasSubclass(exactClassNode)) {
      /// A member from a super class can be accessed.
      return true;
    }
    for (ClassHierarchyNode mixinApplication
        in memberHoldingClassSet.mixinApplicationNodes) {
      if (mixinApplication.hasSubclass(exactClassNode)) {
        /// A member from a mixed in class can be accessed.
        return true;
      }
    }
    return false;
  }

  final Map<ClassEntity, _InheritedInThisClassCache>
  _inheritedInThisClassCacheMap = {};

  /// Returns `true` if a `this` expression in [thisClass] can target a member
  /// declared in [memberHoldingClass].
  bool isInheritedInThisClass(
    ClassEntity memberHoldingClass,
    ClassEntity thisClass,
  ) {
    _InheritedInThisClassCache cache =
        _inheritedInThisClassCacheMap[memberHoldingClass] ??=
            _InheritedInThisClassCache();
    return cache.isInheritedInThisClassOf(this, memberHoldingClass, thisClass);
  }

  final Map<ClassEntity, _InheritedInSubtypeCache> _inheritedInSubtypeCacheMap =
      {};

  bool isInheritedInSubtypeOf(ClassEntity x, ClassEntity y) {
    _InheritedInSubtypeCache cache = _inheritedInSubtypeCacheMap[x] ??=
        _InheritedInSubtypeCache();
    return cache.isInheritedInSubtypeOf(this, x, y);
  }
}

/// Cache used for computing when a member of a given class, the so-called
/// member holding class, can be inherited into a live class.
class _InheritedInThisClassCache {
  /// Set of classes that inherits members from the member holding class.
  Set<ClassEntity>? _inheritingClasses;

  /// Cache for liveness computation for a `this` expressions of a given class.
  Map<ClassEntity, _LiveSet>? _map;

  /// Returns `true` if members of [memberHoldingClass] can be inherited into
  /// a live class that can be the target of a `this` expression in [thisClass].
  bool isInheritedInThisClassOf(
    ClassHierarchyBuilder builder,
    ClassEntity memberHoldingClass,
    ClassEntity thisClass,
  ) {
    _LiveSet? set;
    if (_map == null) {
      _map = {};
    } else {
      set = _map![thisClass];
    }
    set ??= _map![thisClass] = _computeInheritingInThisClassSet(
      builder,
      memberHoldingClass,
      thisClass,
    );
    return set.hasLiveClass(builder);
  }

  _LiveSet _computeInheritingInThisClassSet(
    ClassHierarchyBuilder builder,
    ClassEntity memberHoldingClass,
    ClassEntity thisClass,
  ) {
    ClassHierarchyNode memberHoldingClassNode =
        builder._classHierarchyNodes[memberHoldingClass]!;

    if (_inheritingClasses == null) {
      _inheritingClasses = {};
      _inheritingClasses!.addAll(
        memberHoldingClassNode.subclassesByMask(
          ClassHierarchyNode.all,
          strict: false,
        ),
      );
      for (ClassHierarchyNode mixinApplication
          in builder._classSets[memberHoldingClass]!.mixinApplicationNodes) {
        _inheritingClasses!.addAll(
          mixinApplication.subclassesByMask(
            ClassHierarchyNode.all,
            strict: false,
          ),
        );
      }
    }

    Set<ClassEntity> validatingSet = {};

    void processHierarchy(ClassHierarchyNode mixerNode) {
      for (ClassEntity inheritingClass in _inheritingClasses!) {
        ClassHierarchyNode inheritingClassNode =
            builder._classHierarchyNodes[inheritingClass]!;
        if (!validatingSet.contains(mixerNode.cls) &&
            inheritingClassNode.hasSubclass(mixerNode)) {
          // If [mixerNode.cls] is live then a `this` expression can target
          // members inherited from [memberHoldingClass] into [inheritingClass].
          validatingSet.add(mixerNode.cls);
        }
        if (mixerNode.hasSubclass(inheritingClassNode)) {
          // If [inheritingClass] is live then a `this` expression can target
          // members inherited from [memberHoldingClass] into `inheritingClass`
          // into a subclass of [mixerNode.cls].
          validatingSet.add(inheritingClass);
        }
      }
    }

    ClassSet thisClassSet = builder._classSets[thisClass]!;

    processHierarchy(thisClassSet.node);

    for (ClassHierarchyNode mixinApplication
        in thisClassSet.mixinApplicationNodes) {
      processHierarchy(mixinApplication);
    }

    return _LiveSet(validatingSet);
  }
}

/// A cache object used for [ClassHierarchyBuilder.isInheritedInSubtypeOf].
class _InheritedInSubtypeCache {
  Map<ClassEntity, _LiveSet>? _map;

  /// Returns whether a live class currently known to inherit from [x] and
  /// implement [y].
  bool isInheritedInSubtypeOf(
    ClassHierarchyBuilder builder,
    ClassEntity x,
    ClassEntity y,
  ) {
    _LiveSet? set;
    if (_map == null) {
      _map = {};
    } else {
      set = _map![y];
    }
    set ??= _map![y] = _computeInheritingInSubtypeSet(builder, x, y);
    return set.hasLiveClass(builder);
  }

  /// Creates an [_LiveSet] of classes that inherit members of a class [x]
  /// while implementing class [y].
  _LiveSet _computeInheritingInSubtypeSet(
    ClassHierarchyBuilder builder,
    ClassEntity x,
    ClassEntity y,
  ) {
    ClassSet classSet = builder._classSets[x]!;

    Set<ClassEntity> classes = {};

    if (builder._isSubtypeOf(x, y)) {
      // [x] implements [y] itself, possible through supertypes.
      classes.add(x);
    }

    /// Add subclasses of [node] that implement [y].
    void subclassImplements(ClassHierarchyNode node, {required bool strict}) {
      node.forEachSubclass(
        (ClassEntity z) {
          if (builder._isSubtypeOf(z, y)) {
            classes.add(z);
          }
          return IterationStep.continue_;
        },
        ClassHierarchyNode.all,
        strict: strict,
      );
    }

    // A subclasses of [x] that implement [y].
    subclassImplements(classSet.node, strict: true);

    for (ClassHierarchyNode mixinApplication
        in classSet.mixinApplicationNodes) {
      // A subclass of [mixinApplication] implements [y].
      subclassImplements(mixinApplication, strict: false);
    }

    return _LiveSet(classes);
  }
}

/// A set of potentially live classes.
///
/// The set is used [ClassHierarchyBuilder.isInheritedInSubtypeOf] and
/// [ClassHierarchyBuilder.isInheritedInThisClassOf] to determine
/// when members of a class is live.
class _LiveSet {
  /// If `true` the set of classes is known to contain a live class. In this
  /// case [_classes] is `null`. If `false` the set of classes is empty and
  /// therefore known never to contain live classes. In this case [_classes]
  /// is `null`. If `null` [_classes] is a non-empty set containing classes
  /// that are not yet known to be live.
  bool? _result;
  Set<ClassEntity>? _classes;

  _LiveSet(Set<ClassEntity> classes)
    : _result = classes.isEmpty ? false : null,
      _classes = classes.isNotEmpty ? classes : null;

  /// Returns whether the set of classes is currently known to contain a live
  /// classes.
  ///
  /// The result of this method changes during the closed world computation.
  /// Initially, we haven't seen any live classes so we will return `false` even
  /// for a non-empty set of classes. As more classes are marked as
  /// instantiated, during tree-shaking, the result might change to `true` if
  /// one of the [_classes] has been marked as live.
  ///
  /// The result of this method _is_ monotone, though; when we have returned
  /// `true` (because at least one class is known to be live) we will continue
  /// to return `true`.
  bool hasLiveClass(ClassHierarchyBuilder builder) {
    if (_result != null) return _result!;
    for (ClassEntity cls in _classes!) {
      if (builder._classHierarchyNodes[cls]!.isInstantiated) {
        // We now know this set contains a live class and done need to remember
        // that set of classes anymore.
        _result = true;
        _classes = null;
        return true;
      }
    }
    return false;
  }
}

/// Enum values defining subset of classes included in queries.
enum ClassQuery {
  /// Only the class itself is included.
  exact,

  /// The class and all subclasses (transitively) are included.
  subclass,

  /// The class and all classes that implement or subclass it (transitively)
  /// are included.
  subtype,
}

/// Result computed in [ClassHierarchy.commonSubclasses].
sealed class SubclassResult {}

enum SimpleSubclassResult implements SubclassResult {
  /// No common subclasses.
  empty,

  /// Exactly the first class in common.
  exact1,

  /// Exactly the second class in common.
  exact2,

  /// Subclasses of the first class in common.
  subclass1,

  /// Subclasses of the second class in common.
  subclass2,

  /// Subtypes of the first class in common.
  subtype1,

  /// Subtypes of the second class in common.
  subtype2,
}

/// Subclasses of a set of classes in common.
class SetSubclassResult implements SubclassResult {
  final List<ClassEntity> classes;

  SetSubclassResult(this.classes);

  @override
  String toString() => 'SetSubclassResult(classes=$classes)';
}
