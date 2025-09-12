import 'package:hive/hive.dart';
import '../models/wallet_model.dart';

class WalletModelAdapter extends TypeAdapter<WalletModel> {
  @override
  final int typeId = 5;

  @override
  WalletModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return WalletModel(
      id: fields[0] as String,
      name: fields[1] as String,
      balance: (fields[2] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, WalletModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.balance);
  }
}

