import 'package:hive_flutter/hive_flutter.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0) // Changed from 0 to 1 for new version
class UserModel extends HiveObject {
  @HiveField(0)
  int id;
  @HiveField(1)
  String email;
  @HiveField(2)
  String password;
  @HiveField(3)
  Duration creditProgress;
  @HiveField(4)
  int userCredit;
  @HiveField(5)
  String username;
  @HiveField(6)
  int freezeCount;


  UserModel({
    required this.id,
    required this.email,
    required this.password,
    required this.username,
    this.creditProgress = const Duration(hours: 0, minutes: 0, seconds: 0),
    this.userCredit = 0,
    this.freezeCount = 0,

  });
  factory UserModel.fromJson(Map<String, dynamic> json) {
    Duration stringToDuration(String timeString) {
      List<String> split = timeString.split(':');
      return Duration(hours: int.parse(split[0]), minutes: int.parse(split[1]), seconds: int.parse(split[2]));
    }

    return UserModel(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      username: json['username'],
      creditProgress: stringToDuration(json['credit_progress']),
      userCredit: json['user_credit'],
      freezeCount: json['freeze_count'] ?? 0,

    );
  }

  Map<String, dynamic> toJson() {
    String durationToString(Duration duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);

      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return {
      'id': id,
      'email': email,
      'password': password,
      'username': username,
      'credit_progress': durationToString(creditProgress),
      'user_credit': userCredit,
      'freeze_count': freezeCount,

    };
  }
}
