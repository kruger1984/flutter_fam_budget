sealed class FamilyException implements Exception {
  final String message;
  FamilyException(this.message);

  @override
  String toString() => message;
}

class InvalidInviteCodeException extends FamilyException {
  InvalidInviteCodeException() : super('Invalid or expired invite code');
}

class AlreadyInFamilyException extends FamilyException {
  AlreadyInFamilyException() : super('You are already a member of this family');
}

class UnknownFamilyException extends FamilyException {
  UnknownFamilyException([String? message]) : super(message ?? 'Something went wrong');
}