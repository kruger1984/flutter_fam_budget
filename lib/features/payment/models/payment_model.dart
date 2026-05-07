/// Data model for [payment]. Add [fromJson] when the API shape is known
/// (or switch to `freezed` + `json_serializable` if you want codegen).
class PaymentModel {
  const PaymentModel({required this.id});

  final String id;
}
