import '../models/user.dart';
import '../services/storage_service.dart';

class AuthService {
  final StorageService _storageService = StorageService();

  Future<bool> register(String name, String username, String password, int age, String country) async {
    // Check if user already exists
    final existingUser = await _storageService.getUser();
    if (existingUser != null && existingUser.username == username) {
      return false; // User already exists
    }

    final user = User(
      name: name,
      username: username,
      password: password,
      age: age,
      country: country,
    );

    await _storageService.saveUser(user);
    await _storageService.setLoggedIn(true);
    return true;
  }

  Future<bool> login(String username, String password) async {
    final user = await _storageService.getUser();
    if (user != null && user.username == username && user.password == password) {
      await _storageService.setLoggedIn(true);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _storageService.setLoggedIn(false);
  }

  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }

  Future<User?> getCurrentUser() async {
    final isLoggedIn = await _storageService.isLoggedIn();
    if (isLoggedIn) {
      return await _storageService.getUser();
    }
    return null;
  }

  Future<bool> updateProfile(String name, String username, int age, String country) async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(
        name: name,
        username: username,
        age: age,
        country: country,
      );
      await _storageService.saveUser(updatedUser);
      return true;
    }
    return false;
  }
}
