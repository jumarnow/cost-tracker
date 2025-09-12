class WalletModel {
  final String id;
  final String name;
  final double balance;

  const WalletModel({
    required this.id,
    required this.name,
    required this.balance,
  });

  WalletModel copyWith({String? id, String? name, double? balance}) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
    );
  }
}

const defaultWalletId = 'wallet-default';
const defaultWalletName = 'Cash';

