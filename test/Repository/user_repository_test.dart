import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:next_level/Repository/user_repository.dart';
import 'package:next_level/Model/user_model.dart';
import '../helpers/test_helpers.mocks.dart';

void main() {
  late UserRepository userRepository;
  late MockHiveService mockHiveService;

  setUp(() {
    mockHiveService = MockHiveService();
    userRepository = UserRepository();
    userRepository.setHiveService(mockHiveService);
  });

  group('UserRepository Tests', () {
    test('addUser should call hive service', () async {
      final user = UserModel(
        id: 1,
        username: 'Test User',
        email: 'test@test.com',
        password: 'password',
        userCredit: 0,
        creditProgress: Duration.zero,
      );
      when(mockHiveService.addUser(any)).thenAnswer((_) async => Future.value());

      await userRepository.addUser(user);

      verify(mockHiveService.addUser(user)).called(1);
    });

    test('getUser should return user from hive service', () async {
      final user = UserModel(
        id: 1,
        username: 'Test User',
        email: 'test@test.com',
        password: 'password',
        userCredit: 0,
        creditProgress: Duration.zero,
      );
      when(mockHiveService.getUser(1)).thenAnswer((_) async => user);

      final result = await userRepository.getUser(1);

      expect(result, user);
      verify(mockHiveService.getUser(1)).called(1);
    });

    test('updateUser should call hive service', () async {
      final user = UserModel(
        id: 1,
        username: 'Updated User',
        email: 'test@test.com',
        password: 'password',
        userCredit: 10,
        creditProgress: Duration.zero,
      );
      when(mockHiveService.updateUser(any)).thenAnswer((_) async => Future.value());

      await userRepository.updateUser(user);

      verify(mockHiveService.updateUser(user)).called(1);
    });
  });
}
