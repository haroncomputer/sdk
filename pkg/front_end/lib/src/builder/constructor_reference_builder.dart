// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../base/messages.dart' show noLength, templateConstructorNotFound;
import '../base/scope.dart';
import 'builder.dart';
import 'declaration_builders.dart';
import 'library_builder.dart';
import 'prefix_builder.dart';
import 'type_builder.dart';

class ConstructorReferenceBuilder {
  final int charOffset;

  final Uri fileUri;

  final TypeName typeName;

  final List<TypeBuilder>? typeArguments;

  /// This is the name of a named constructor. As `bar` in `new Foo<T>.bar()`.
  final String? suffix;

  Builder? target;

  ConstructorReferenceBuilder(this.typeName, this.typeArguments, this.suffix,
      this.fileUri, this.charOffset);

  String get fullNameForErrors {
    return "${typeName.fullName}"
        "${suffix == null ? '' : '.$suffix'}";
  }

  void resolveIn(LookupScope scope, LibraryBuilder accessingLibrary) {
    Builder? declaration;
    String? qualifier = typeName.qualifier;
    if (qualifier != null) {
      String prefix = qualifier;
      String middle = typeName.name;
      declaration = scope.lookup(prefix, charOffset, fileUri)?.getable;
      if (declaration is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = declaration;
        declaration = aliasBuilder.unaliasDeclaration(typeArguments);
      }
      if (declaration is PrefixBuilder) {
        PrefixBuilder prefix = declaration;
        declaration =
            prefix.lookup(middle, typeName.nameOffset, fileUri)?.getable;
      } else if (declaration is DeclarationBuilder) {
        declaration = declaration.findConstructorOrFactory(
            middle, typeName.nameOffset, fileUri, accessingLibrary);
        if (suffix == null) {
          target = declaration;
          return;
        }
      }
    } else {
      declaration = scope.lookup(typeName.name, charOffset, fileUri)?.getable;
      if (declaration is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = declaration;
        declaration = aliasBuilder.unaliasDeclaration(typeArguments);
      }
    }
    if (declaration is DeclarationBuilder) {
      target = declaration.findConstructorOrFactory(
          suffix ?? "", charOffset, fileUri, accessingLibrary);
    }
    if (target == null) {
      accessingLibrary.addProblem(
          templateConstructorNotFound.withArguments(fullNameForErrors),
          charOffset,
          noLength,
          fileUri);
    }
  }
}
