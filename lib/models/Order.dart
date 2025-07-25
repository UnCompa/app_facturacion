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


/** This is an auto generated class representing the Order type in your schema. */
class Order extends amplify_core.Model {
  static const classType = const _OrderModelType();
  final String id;
  final String? _orderNumber;
  final amplify_core.TemporalDateTime? _orderDate;
  final double? _orderTotal;
  final String? _orderStatus;
  final List<OrderItem>? _orderItems;
  final List<String>? _orderImages;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  OrderModelIdentifier get modelIdentifier {
      return OrderModelIdentifier(
        id: id
      );
  }
  
  String get orderNumber {
    try {
      return _orderNumber!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalDateTime get orderDate {
    try {
      return _orderDate!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  double get orderTotal {
    try {
      return _orderTotal!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get orderStatus {
    return _orderStatus;
  }
  
  List<OrderItem>? get orderItems {
    return _orderItems;
  }
  
  List<String>? get orderImages {
    return _orderImages;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Order._internal({required this.id, required orderNumber, required orderDate, required orderTotal, orderStatus, orderItems, orderImages, createdAt, updatedAt}): _orderNumber = orderNumber, _orderDate = orderDate, _orderTotal = orderTotal, _orderStatus = orderStatus, _orderItems = orderItems, _orderImages = orderImages, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Order({String? id, required String orderNumber, required amplify_core.TemporalDateTime orderDate, required double orderTotal, String? orderStatus, List<OrderItem>? orderItems, List<String>? orderImages, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Order._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      orderNumber: orderNumber,
      orderDate: orderDate,
      orderTotal: orderTotal,
      orderStatus: orderStatus,
      orderItems: orderItems != null ? List<OrderItem>.unmodifiable(orderItems) : orderItems,
      orderImages: orderImages != null ? List<String>.unmodifiable(orderImages) : orderImages,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Order &&
      id == other.id &&
      _orderNumber == other._orderNumber &&
      _orderDate == other._orderDate &&
      _orderTotal == other._orderTotal &&
      _orderStatus == other._orderStatus &&
      DeepCollectionEquality().equals(_orderItems, other._orderItems) &&
      DeepCollectionEquality().equals(_orderImages, other._orderImages) &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Order {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("orderNumber=" + "$_orderNumber" + ", ");
    buffer.write("orderDate=" + (_orderDate != null ? _orderDate.format() : "null") + ", ");
    buffer.write("orderTotal=" + (_orderTotal != null ? _orderTotal.toString() : "null") + ", ");
    buffer.write("orderStatus=" + "$_orderStatus" + ", ");
    buffer.write("orderImages=" + (_orderImages != null ? _orderImages.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Order copyWith({String? orderNumber, amplify_core.TemporalDateTime? orderDate, double? orderTotal, String? orderStatus, List<OrderItem>? orderItems, List<String>? orderImages, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Order._internal(
      id: id,
      orderNumber: orderNumber ?? this.orderNumber,
      orderDate: orderDate ?? this.orderDate,
      orderTotal: orderTotal ?? this.orderTotal,
      orderStatus: orderStatus ?? this.orderStatus,
      orderItems: orderItems ?? this.orderItems,
      orderImages: orderImages ?? this.orderImages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  Order copyWithModelFieldValues({
    ModelFieldValue<String>? orderNumber,
    ModelFieldValue<amplify_core.TemporalDateTime>? orderDate,
    ModelFieldValue<double>? orderTotal,
    ModelFieldValue<String?>? orderStatus,
    ModelFieldValue<List<OrderItem>?>? orderItems,
    ModelFieldValue<List<String>?>? orderImages,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return Order._internal(
      id: id,
      orderNumber: orderNumber == null ? this.orderNumber : orderNumber.value,
      orderDate: orderDate == null ? this.orderDate : orderDate.value,
      orderTotal: orderTotal == null ? this.orderTotal : orderTotal.value,
      orderStatus: orderStatus == null ? this.orderStatus : orderStatus.value,
      orderItems: orderItems == null ? this.orderItems : orderItems.value,
      orderImages: orderImages == null ? this.orderImages : orderImages.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  Order.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _orderNumber = json['orderNumber'],
      _orderDate = json['orderDate'] != null ? amplify_core.TemporalDateTime.fromString(json['orderDate']) : null,
      _orderTotal = (json['orderTotal'] as num?)?.toDouble(),
      _orderStatus = json['orderStatus'],
      _orderItems = json['orderItems']  is Map
        ? (json['orderItems']['items'] is List
          ? (json['orderItems']['items'] as List)
              .where((e) => e != null)
              .map((e) => OrderItem.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['orderItems'] is List
          ? (json['orderItems'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => OrderItem.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _orderImages = json['orderImages']?.cast<String>(),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'orderNumber': _orderNumber, 'orderDate': _orderDate?.format(), 'orderTotal': _orderTotal, 'orderStatus': _orderStatus, 'orderItems': _orderItems?.map((OrderItem? e) => e?.toJson()).toList(), 'orderImages': _orderImages, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'orderNumber': _orderNumber,
    'orderDate': _orderDate,
    'orderTotal': _orderTotal,
    'orderStatus': _orderStatus,
    'orderItems': _orderItems,
    'orderImages': _orderImages,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<OrderModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<OrderModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final ORDERNUMBER = amplify_core.QueryField(fieldName: "orderNumber");
  static final ORDERDATE = amplify_core.QueryField(fieldName: "orderDate");
  static final ORDERTOTAL = amplify_core.QueryField(fieldName: "orderTotal");
  static final ORDERSTATUS = amplify_core.QueryField(fieldName: "orderStatus");
  static final ORDERITEMS = amplify_core.QueryField(
    fieldName: "orderItems",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'OrderItem'));
  static final ORDERIMAGES = amplify_core.QueryField(fieldName: "orderImages");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Order";
    modelSchemaDefinition.pluralName = "Orders";
    
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
      key: Order.ORDERNUMBER,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Order.ORDERDATE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Order.ORDERTOTAL,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Order.ORDERSTATUS,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: Order.ORDERITEMS,
      isRequired: false,
      ofModelName: 'OrderItem',
      associatedKey: OrderItem.ORDERID
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Order.ORDERIMAGES,
      isRequired: false,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.collection, ofModelName: amplify_core.ModelFieldTypeEnum.string.name)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Order.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Order.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _OrderModelType extends amplify_core.ModelType<Order> {
  const _OrderModelType();
  
  @override
  Order fromJson(Map<String, dynamic> jsonData) {
    return Order.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Order';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Order] in your schema.
 */
class OrderModelIdentifier implements amplify_core.ModelIdentifier<Order> {
  final String id;

  /** Create an instance of OrderModelIdentifier using [id] the primary key. */
  const OrderModelIdentifier({
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
  String toString() => 'OrderModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is OrderModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}