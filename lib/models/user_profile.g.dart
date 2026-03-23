part of 'user_profile.dart';

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 2;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      name: fields[0] as String,
      preferredGreeting: fields[1] as String,
      interests: (fields[2] as List?)?.cast<String>() ?? [],
      preferences: (fields[3] as Map?)?.cast<String, dynamic>() ?? {},
      createdAt: fields[4] as DateTime,
      lastActive: fields[5] as DateTime,
      totalConversations: fields[6] as int,
      profileImagePath: fields[7] as String?,
      voicePreference: fields[8] as String,
      speechRate: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.preferredGreeting)
      ..writeByte(2)
      ..write(obj.interests)
      ..writeByte(3)
      ..write(obj.preferences)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastActive)
      ..writeByte(6)
      ..write(obj.totalConversations)
      ..writeByte(7)
      ..write(obj.profileImagePath)
      ..writeByte(8)
      ..write(obj.voicePreference)
      ..writeByte(9)
      ..write(obj.speechRate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
