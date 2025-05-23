// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/clone.dart' as ir;
import 'package:kernel/type_algebra.dart' as ir;

import '../kernel/element_map.dart';
import 'impact_data.dart';

/// Handles conditional impact creation for protobuf metadata.
///
/// Consider the following protobuf message:
/// ```
/// message Name {
///   optional string value;
/// }
///
/// message Person {
///   optional Name name;
/// }
/// ```
///
/// which roughly translates to this generated code:
///
/// ```
/// class Name extends $pb.GeneratedMessage {
///   static final $pb.BuilderInfo _i = $pb.BuilderInfo('Name')
///     ..oS(1, 'value');
///
///   static Name create() => Name._();
///
///   // Accessors for value //
///   @$pb.TagNumber(1)
///   String get value => $_getSZ(0);
///   @$pb.TagNumber(1)
///   set value(String v) { $_setString(0, v); }
///   @$pb.TagNumber(1)
///   $core.bool hasValue() => $_has(0);
///   @$pb.TagNumber(1)
///   void clearValue() => clearField(1);
/// }
///
/// class Person extends $pb.GeneratedMessage {
///   static final $pb.BuilderInfo _i = $pb.BuilderInfo('Person')
///     ..aOM<Name>(1, 'name', subBuilder: Name.create); // name metadata initalizer
///
///   static Person create() => Person._();
///
///   // Accessors for name //
///   @$pb.TagNumber(1)
///   Name get name => $_getN(0);
///   @$pb.TagNumber(1)
///   set name(Name v) { setField(0, v); }
///   @$pb.TagNumber(1)
///   $core.bool hasName() => $_has(0);
///   @$pb.TagNumber(1)
///   void clearName() => clearField(1);
/// }
/// ```
///
/// We refer to `..aOM<Name>(1, 'name', subBuilder: Name.create)` as the
/// metadata initializer for `name`. We consider `name` unreachable if none of
/// the accessors for `name` are invoked anywhere in the program.
///
/// If `name` is unreachable then we can replace the metadata initializer for
/// `name` with a placeholder. This would remove the reference to `Name.create`
/// so we consider the usage of `Name.create` to be conditional on any of the
/// `name` accessors being invoked. Furthermore, if `Name` is only instantiated
/// from an unreachable metadata initializer, the `Name` class itself is also
/// unreachable and can be pruned.
class ProtobufImpactHandler implements ConditionalImpactHandler {
  static const String protobufLibraryUri = 'package:protobuf/protobuf.dart';

  static bool _hasGeneratedMessageSuperclass(
    ir.Class protobufGeneratedMessageClass,
    ir.Class enclosingClass,
  ) {
    ir.Class? current = enclosingClass;
    while (current != null) {
      if (current == protobufGeneratedMessageClass) return true;

      current = current.superclass;
    }
    return false;
  }

  static ProtobufImpactHandler? createIfApplicable(
    KernelToElementMap elementMap,
    ir.Member node,
  ) {
    if (!elementMap.options.enableProtoShaking) return null;

    if (node.name.text != metadataFieldName) return null;

    // Not all programs will include the protobuf library. Ideally those
    // programs wouldn't enable proto shaking but we can be conservative and not
    // assume the library exists.
    final protobufGeneratedMessageClass = elementMap.env.libraryIndex
        .tryGetClass(protobufLibraryUri, 'GeneratedMessage');

    if (protobufGeneratedMessageClass == null) return null;

    final enclosingClass = node.enclosingClass;
    if (enclosingClass == null) return null;

    // Applicable if the member is in a subclass of GeneratedMessage.
    if (enclosingClass.superclass == protobufGeneratedMessageClass) {
      return ProtobufImpactHandler._(elementMap, enclosingClass);
    }

    // Applicable if the member is in a subclass of GeneratedMessage with mixins
    // included.
    if (elementMap.options.enableProtoMixinShaking) {
      final superclass = enclosingClass.superclass;
      if (superclass != null &&
          superclass.isMixinApplication &&
          _hasGeneratedMessageSuperclass(
            protobufGeneratedMessageClass,
            superclass,
          )) {
        return ProtobufImpactHandler._(elementMap, enclosingClass);
      }
    }
    return null;
  }

  final KernelToElementMap _elementMap;
  final ir.Class _messageClass;
  ImpactData? _impactData;

  ProtobufImpactHandler._(this._elementMap, this._messageClass);

  late final ir.Class _builderInfoClass = _elementMap.env.libraryIndex.getClass(
    protobufLibraryUri,
    'BuilderInfo',
  );
  late final ir.Class _tagNumberClass = _elementMap.env.libraryIndex.getClass(
    protobufLibraryUri,
    'TagNumber',
  );
  late final ir.Field _tagNumberField = _elementMap.env.libraryIndex.getField(
    protobufLibraryUri,
    'TagNumber',
    'tagNumber',
  );
  late final ir.Procedure _builderInfoAddMethod = _elementMap.env.libraryIndex
      .getProcedure(protobufLibraryUri, 'BuilderInfo', 'add');
  late final ir.FunctionType _typeOfBuilderInfoAddOfNull =
      ir.FunctionTypeInstantiator.instantiate(
        _builderInfoAddMethod.getterType as ir.FunctionType,
        const <ir.DartType>[ir.NullType()],
      );

  late final ir.Procedure? _builderInfoAddUnusedMethod = _elementMap
      .env
      .libraryIndex
      .tryGetProcedure(protobufLibraryUri, 'BuilderInfo', 'addUnused');

  static const String metadataFieldName = '_i';

  // All of those methods have the dart field name as second positional
  // parameter.
  // Method names are defined in:
  // https://github.com/google/protobuf.dart/blob/master/protobuf/lib/src/protobuf/builder_info.dart
  // The methods are called in code generated by:
  // https://github.com/google/protobuf.dart/blob/master/protoc_plugin/lib/src/protobuf_field.dart
  static const Set<String> metadataInitializers = {
    'a',
    'aD',
    'aI',
    'aOM',
    'aOS',
    'aQM',
    'pPS',
    'aQS',
    'aInt64',
    'aOB',
    'e',
    'aE',
    'p',
    'pc',
    'pPM',
    'pPE',
    'm',
  };

  ir.InstanceInvocation _buildProtobufMetadataPlaceholder(
    ir.InstanceInvocation node,
  ) {
    final addUnusedMethod = _builderInfoAddUnusedMethod;
    if (addUnusedMethod == null) {
      // Legacy version, call `add` method.
      return ir.InstanceInvocation(
        ir.InstanceAccessKind.Instance,
        _CloneVisitorLenientVariables().clone(node.receiver),
        _builderInfoAddMethod.name,
        ir.Arguments(
          <ir.Expression>[
            ir.IntLiteral(0), // tagNumber
            ir.NullLiteral(), // name
            ir.NullLiteral(), // fieldType
            ir.NullLiteral(), // defaultOrMaker
            ir.NullLiteral(), // subBuilder
            ir.NullLiteral(), // valueOf
            ir.NullLiteral(), // enumValues
          ],
          types: <ir.DartType>[const ir.NullType()],
        ),
        interfaceTarget: _builderInfoAddMethod,
        functionType: _typeOfBuilderInfoAddOfNull,
      )..fileOffset = node.fileOffset;
    } else {
      // New version, call `addUnused` method.
      return ir.InstanceInvocation(
        ir.InstanceAccessKind.Instance,
        _CloneVisitorLenientVariables().clone(node.receiver),
        addUnusedMethod.name,
        ir.Arguments([]),
        interfaceTarget: addUnusedMethod,
        functionType: addUnusedMethod.getterType as ir.FunctionType,
      )..fileOffset = node.fileOffset;
    }
  }

  @override
  ImpactData? beforeInstanceInvocation(ir.InstanceInvocation node) {
    final interfaceTarget = node.interfaceTarget;

    // Check if this is a metadata initializer. If so its impacts are
    // conditional on the associated field being reachable.
    return _impactData =
        interfaceTarget.enclosingClass == _builderInfoClass &&
            metadataInitializers.contains(node.name.text)
        ? ImpactData()
        : null;
  }

  @override
  ConditionalImpactData? afterInstanceInvocation(ir.InstanceInvocation node) {
    // This instance invocation is not a metadata initializer.
    if (_impactData == null) return null;

    // The tag number is always the first argument in a metadata initializer.
    final tagNumber =
        ((node.arguments.positional[0] as ir.ConstantExpression).constant
                as ir.DoubleConstant)
            .value
            .toInt();

    // Iterate through all the accessors and find ones which are annotated
    // with a matching tag number. These are the accessors that the current
    // metadata initializer is conditional on.
    final accessors = <ir.Member>[];
    for (final procedure in _messageClass.procedures) {
      for (final annotation in procedure.annotations) {
        final constant = (annotation as ir.ConstantExpression).constant;
        if (constant is ir.InstanceConstant &&
            constant.classReference == _tagNumberClass.reference) {
          final procedureTagNumber =
              (constant.fieldValues[_tagNumberField.fieldReference]
                      as ir.DoubleConstant)
                  .value
                  .toInt();
          if (tagNumber == procedureTagNumber) {
            accessors.add(procedure);
          }
        }
      }
    }
    return ConditionalImpactData(
      accessors,
      _impactData!,
      original: node,
      replacement: _buildProtobufMetadataPlaceholder(node),
    );
  }
}

/// Clones nodes but returns same variable declaration on VariableGet if the
/// declaration is not in scope.
class _CloneVisitorLenientVariables extends ir.CloneVisitorNotMembers {
  @override
  ir.VariableDeclaration getVariableClone(ir.VariableDeclaration variable) {
    return super.getVariableClone(variable) ?? variable;
  }
}
