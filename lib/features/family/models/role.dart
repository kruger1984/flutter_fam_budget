import 'package:freezed_annotation/freezed_annotation.dart';

enum Role {
  @JsonValue('member') member,
  @JsonValue('owner') owner,
}