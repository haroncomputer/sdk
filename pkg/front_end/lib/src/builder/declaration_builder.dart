// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

abstract class IDeclarationBuilder implements ITypeDeclarationBuilder {
  DeclarationNameSpace get nameSpace;

  /// Type parameters declared on this declaration.
  ///
  /// This is `null` if the declaration is not generic.
  List<NominalParameterBuilder>? get typeParameters;

  LibraryBuilder get libraryBuilder;

  @override
  Uri get fileUri;

  /// Lookup a member accessed statically through this declaration.
  LookupResult? findStaticBuilder(String name, int fileOffset, Uri fileUri,
      LibraryBuilder accessingLibrary);

  MemberBuilder? findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder accessingLibrary);

  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled = false, List<LocatedMessage>? context});

  /// Returns the type of `this` in an instance of this declaration.
  ///
  /// This is non-null for class and mixin declarations and `null` for
  /// extension declarations.
  InterfaceType? get thisType;

  /// Lookups the member [name] declared in this declaration.
  ///
  /// If [setter] is `true` the sought member is a setter or assignable field.
  /// If [required] is `true` and no member is found an internal problem is
  /// reported.
  NamedBuilder? lookupLocalMember(String name,
      {bool setter = false, bool required = false});

  List<DartType> buildAliasedTypeArguments(LibraryBuilder library,
      List<TypeBuilder>? arguments, ClassHierarchyBase? hierarchy);
}

abstract class DeclarationBuilderImpl extends TypeDeclarationBuilderImpl
    implements IDeclarationBuilder {
  @override
  LibraryBuilder get parent;

  @override
  LibraryBuilder get libraryBuilder {
    return parent.partOfLibrary ?? parent;
  }

  @override
  MemberBuilder? findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder accessingLibrary) {
    if (accessingLibrary.nameOriginBuilder !=
            libraryBuilder.nameOriginBuilder &&
        name.startsWith("_")) {
      return null;
    }
    MemberBuilder? declaration =
        nameSpace.lookupConstructor(name == 'new' ? '' : name);
    if (declaration != null && declaration.next != null) {
      return new AmbiguousMemberBuilder(
          name.isEmpty ? this.name : name, declaration, charOffset, fileUri);
    }

    return declaration;
  }

  @override
  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled = false, List<LocatedMessage>? context}) {
    libraryBuilder.addProblem(message, charOffset, length, fileUri,
        wasHandled: wasHandled, context: context);
  }
}
