import '../../models/address.model.dart';

abstract class AddressState {
  const AddressState();
}

class AddressInitial extends AddressState {
  const AddressInitial();
}

class AddressLoading extends AddressState {
  const AddressLoading();
}

class AddressLoaded extends AddressState {
  final List<AddressModel> addresses;
  final String? actionError;

  const AddressLoaded(this.addresses, {this.actionError});

  AddressLoaded copyWith({List<AddressModel>? addresses, String? actionError}) {
    return AddressLoaded(addresses ?? this.addresses, actionError: actionError);
  }
}

class AddressFailure extends AddressState {
  final String error;
  const AddressFailure(this.error);
}
