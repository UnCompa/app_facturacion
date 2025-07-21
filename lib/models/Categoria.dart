/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;
import 'package:collection/collection.dart';


/** This is an auto generated class representing the Categoria type in your schema. */
class Categoria extends amplify_core.Model {
  static const classType = const _CategoriaModelType();
  final String id;
  final String? _nombre;
  final String? _parentCategoriaID;
  final List<Producto>? _productos;
  final List<Categoria>? _subCategorias;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  CategoriaModelIdentifier get modelIdentifier {
      return CategoriaModelIdentifier(
        id: id
      );
  }
  
  String get nombre {
    try {
      return _nombre!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get parentCategoriaID {
    return _parentCategoriaID;
  }
  
  List<Producto>? get productos {
    return _productos;
  }
  
  List<Categoria>? get subCategorias {
    return _subCategorias;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Categoria._internal({required this.id, required nombre, parentCategoriaID, productos, subCategorias, createdAt, updatedAt}): _nombre = nombre, _parentCategoriaID = parentCategoriaID, _productos = productos, _subCategorias = subCategorias, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Categoria({String? id, required String nombre, String? parentCategoriaID, List<Producto>? productos, List<Categoria>? subCategorias}) {
    return Categoria._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      nombre: nombre,
      parentCategoriaID: parentCategoriaID,
      productos: productos != null ? List<Producto>.unmodifiable(productos) : productos,
      subCategorias: subCategorias != null ? List<Categoria>.unmodifiable(subCategorias) : subCategorias);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Categoria &&
      id == other.id &&
      _nombre == other._nombre &&
      _parentCategoriaID == other._parentCategoriaID &&
      DeepCollectionEquality().equals(_productos, other._productos) &&
      DeepCollectionEquality().equals(_subCategorias, other._subCategorias);
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Categoria {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("nombre=" + "$_nombre" + ", ");
    buffer.write("parentCategoriaID=" + "$_parentCategoriaID" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Categoria copyWith({String? nombre, String? parentCategoriaID, List<Producto>? productos, List<Categoria>? subCategorias}) {
    return Categoria._internal(
      id: id,
      nombre: nombre ?? this.nombre,
      parentCategoriaID: parentCategoriaID ?? this.parentCategoriaID,
      productos: productos ?? this.productos,
      subCategorias: subCategorias ?? this.subCategorias);
  }
  
  Categoria copyWithModelFieldValues({
    ModelFieldValue<String>? nombre,
    ModelFieldValue<String?>? parentCategoriaID,
    ModelFieldValue<List<Producto>?>? productos,
    ModelFieldValue<List<Categoria>?>? subCategorias
  }) {
    return Categoria._internal(
      id: id,
      nombre: nombre == null ? this.nombre : nombre.value,
      parentCategoriaID: parentCategoriaID == null ? this.parentCategoriaID : parentCategoriaID.value,
      productos: productos == null ? this.productos : productos.value,
      subCategorias: subCategorias == null ? this.subCategorias : subCategorias.value
    );
  }
  
  Categoria.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _nombre = json['nombre'],
      _parentCategoriaID = json['parentCategoriaID'],
      _productos = json['productos']  is Map
        ? (json['productos']['items'] is List
          ? (json['productos']['items'] as List)
              .where((e) => e != null)
              .map((e) => Producto.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['productos'] is List
          ? (json['productos'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => Producto.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _subCategorias = json['subCategorias']  is Map
        ? (json['subCategorias']['items'] is List
          ? (json['subCategorias']['items'] as List)
              .where((e) => e != null)
              .map((e) => Categoria.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['subCategorias'] is List
          ? (json['subCategorias'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => Categoria.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'nombre': _nombre, 'parentCategoriaID': _parentCategoriaID, 'productos': _productos?.map((Producto? e) => e?.toJson()).toList(), 'subCategorias': _subCategorias?.map((Categoria? e) => e?.toJson()).toList(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'nombre': _nombre,
    'parentCategoriaID': _parentCategoriaID,
    'productos': _productos,
    'subCategorias': _subCategorias,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<CategoriaModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<CategoriaModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final NOMBRE = amplify_core.QueryField(fieldName: "nombre");
  static final PARENTCATEGORIAID = amplify_core.QueryField(fieldName: "parentCategoriaID");
  static final PRODUCTOS = amplify_core.QueryField(
    fieldName: "productos",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Producto'));
  static final SUBCATEGORIAS = amplify_core.QueryField(
    fieldName: "subCategorias",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Categoria'));
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Categoria";
    modelSchemaDefinition.pluralName = "Categorias";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.GROUPS,
        groupClaim: "cognito:groups",
        groups: [ "admin", "vendedor" ],
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["parentCategoriaID"], name: "byParentCategoria")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Categoria.NOMBRE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Categoria.PARENTCATEGORIAID,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: Categoria.PRODUCTOS,
      isRequired: false,
      ofModelName: 'Producto',
      associatedKey: Producto.CATEGORIA
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: Categoria.SUBCATEGORIAS,
      isRequired: false,
      ofModelName: 'Categoria',
      associatedKey: Categoria.PARENTCATEGORIAID
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _CategoriaModelType extends amplify_core.ModelType<Categoria> {
  const _CategoriaModelType();
  
  @override
  Categoria fromJson(Map<String, dynamic> jsonData) {
    return Categoria.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Categoria';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Categoria] in your schema.
 */
class CategoriaModelIdentifier implements amplify_core.ModelIdentifier<Categoria> {
  final String id;

  /** Create an instance of CategoriaModelIdentifier using [id] the primary key. */
  const CategoriaModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'CategoriaModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is CategoriaModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}