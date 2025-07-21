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


/** This is an auto generated class representing the Invoice type in your schema. */
class Invoice extends amplify_core.Model {
  static const classType = const _InvoiceModelType();
  final String id;
  final String? _invoiceNumber;
  final amplify_core.TemporalDateTime? _invoiceDate;
  final double? _invoiceTotal;
  final String? _invoiceStatus;
  final List<InvoiceItem>? _invoiceItems;
  final List<String>? _invoiceImages;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  InvoiceModelIdentifier get modelIdentifier {
      return InvoiceModelIdentifier(
        id: id
      );
  }
  
  String get invoiceNumber {
    try {
      return _invoiceNumber!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalDateTime get invoiceDate {
    try {
      return _invoiceDate!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  double get invoiceTotal {
    try {
      return _invoiceTotal!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get invoiceStatus {
    return _invoiceStatus;
  }
  
  List<InvoiceItem>? get invoiceItems {
    return _invoiceItems;
  }
  
  List<String>? get invoiceImages {
    return _invoiceImages;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Invoice._internal({required this.id, required invoiceNumber, required invoiceDate, required invoiceTotal, invoiceStatus, invoiceItems, invoiceImages, createdAt, updatedAt}): _invoiceNumber = invoiceNumber, _invoiceDate = invoiceDate, _invoiceTotal = invoiceTotal, _invoiceStatus = invoiceStatus, _invoiceItems = invoiceItems, _invoiceImages = invoiceImages, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Invoice({String? id, required String invoiceNumber, required amplify_core.TemporalDateTime invoiceDate, required double invoiceTotal, String? invoiceStatus, List<InvoiceItem>? invoiceItems, List<String>? invoiceImages, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Invoice._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      invoiceTotal: invoiceTotal,
      invoiceStatus: invoiceStatus,
      invoiceItems: invoiceItems != null ? List<InvoiceItem>.unmodifiable(invoiceItems) : invoiceItems,
      invoiceImages: invoiceImages != null ? List<String>.unmodifiable(invoiceImages) : invoiceImages,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Invoice &&
      id == other.id &&
      _invoiceNumber == other._invoiceNumber &&
      _invoiceDate == other._invoiceDate &&
      _invoiceTotal == other._invoiceTotal &&
      _invoiceStatus == other._invoiceStatus &&
      DeepCollectionEquality().equals(_invoiceItems, other._invoiceItems) &&
      DeepCollectionEquality().equals(_invoiceImages, other._invoiceImages) &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Invoice {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("invoiceNumber=" + "$_invoiceNumber" + ", ");
    buffer.write("invoiceDate=" + (_invoiceDate != null ? _invoiceDate!.format() : "null") + ", ");
    buffer.write("invoiceTotal=" + (_invoiceTotal != null ? _invoiceTotal!.toString() : "null") + ", ");
    buffer.write("invoiceStatus=" + "$_invoiceStatus" + ", ");
    buffer.write("invoiceImages=" + (_invoiceImages != null ? _invoiceImages!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Invoice copyWith({String? invoiceNumber, amplify_core.TemporalDateTime? invoiceDate, double? invoiceTotal, String? invoiceStatus, List<InvoiceItem>? invoiceItems, List<String>? invoiceImages, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Invoice._internal(
      id: id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      invoiceTotal: invoiceTotal ?? this.invoiceTotal,
      invoiceStatus: invoiceStatus ?? this.invoiceStatus,
      invoiceItems: invoiceItems ?? this.invoiceItems,
      invoiceImages: invoiceImages ?? this.invoiceImages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  Invoice copyWithModelFieldValues({
    ModelFieldValue<String>? invoiceNumber,
    ModelFieldValue<amplify_core.TemporalDateTime>? invoiceDate,
    ModelFieldValue<double>? invoiceTotal,
    ModelFieldValue<String?>? invoiceStatus,
    ModelFieldValue<List<InvoiceItem>?>? invoiceItems,
    ModelFieldValue<List<String>?>? invoiceImages,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return Invoice._internal(
      id: id,
      invoiceNumber: invoiceNumber == null ? this.invoiceNumber : invoiceNumber.value,
      invoiceDate: invoiceDate == null ? this.invoiceDate : invoiceDate.value,
      invoiceTotal: invoiceTotal == null ? this.invoiceTotal : invoiceTotal.value,
      invoiceStatus: invoiceStatus == null ? this.invoiceStatus : invoiceStatus.value,
      invoiceItems: invoiceItems == null ? this.invoiceItems : invoiceItems.value,
      invoiceImages: invoiceImages == null ? this.invoiceImages : invoiceImages.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  Invoice.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _invoiceNumber = json['invoiceNumber'],
      _invoiceDate = json['invoiceDate'] != null ? amplify_core.TemporalDateTime.fromString(json['invoiceDate']) : null,
      _invoiceTotal = (json['invoiceTotal'] as num?)?.toDouble(),
      _invoiceStatus = json['invoiceStatus'],
      _invoiceItems = json['invoiceItems']  is Map
        ? (json['invoiceItems']['items'] is List
          ? (json['invoiceItems']['items'] as List)
              .where((e) => e != null)
              .map((e) => InvoiceItem.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['invoiceItems'] is List
          ? (json['invoiceItems'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => InvoiceItem.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _invoiceImages = json['invoiceImages']?.cast<String>(),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'invoiceNumber': _invoiceNumber, 'invoiceDate': _invoiceDate?.format(), 'invoiceTotal': _invoiceTotal, 'invoiceStatus': _invoiceStatus, 'invoiceItems': _invoiceItems?.map((InvoiceItem? e) => e?.toJson()).toList(), 'invoiceImages': _invoiceImages, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'invoiceNumber': _invoiceNumber,
    'invoiceDate': _invoiceDate,
    'invoiceTotal': _invoiceTotal,
    'invoiceStatus': _invoiceStatus,
    'invoiceItems': _invoiceItems,
    'invoiceImages': _invoiceImages,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<InvoiceModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<InvoiceModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final INVOICENUMBER = amplify_core.QueryField(fieldName: "invoiceNumber");
  static final INVOICEDATE = amplify_core.QueryField(fieldName: "invoiceDate");
  static final INVOICETOTAL = amplify_core.QueryField(fieldName: "invoiceTotal");
  static final INVOICESTATUS = amplify_core.QueryField(fieldName: "invoiceStatus");
  static final INVOICEITEMS = amplify_core.QueryField(
    fieldName: "invoiceItems",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'InvoiceItem'));
  static final INVOICEIMAGES = amplify_core.QueryField(fieldName: "invoiceImages");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Invoice";
    modelSchemaDefinition.pluralName = "Invoices";
    
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
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invoice.INVOICENUMBER,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invoice.INVOICEDATE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invoice.INVOICETOTAL,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invoice.INVOICESTATUS,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: Invoice.INVOICEITEMS,
      isRequired: false,
      ofModelName: 'InvoiceItem',
      associatedKey: InvoiceItem.INVOICEID
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invoice.INVOICEIMAGES,
      isRequired: false,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.collection, ofModelName: amplify_core.ModelFieldTypeEnum.string.name)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invoice.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invoice.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _InvoiceModelType extends amplify_core.ModelType<Invoice> {
  const _InvoiceModelType();
  
  @override
  Invoice fromJson(Map<String, dynamic> jsonData) {
    return Invoice.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Invoice';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Invoice] in your schema.
 */
class InvoiceModelIdentifier implements amplify_core.ModelIdentifier<Invoice> {
  final String id;

  /** Create an instance of InvoiceModelIdentifier using [id] the primary key. */
  const InvoiceModelIdentifier({
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
  String toString() => 'InvoiceModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is InvoiceModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}