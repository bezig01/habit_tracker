import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested(this.username, this.password);

  @override
  List<Object?> get props => [username, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String username;
  final String password;
  final int age;
  final String country;

  const AuthRegisterRequested(
    this.name,
    this.username,
    this.password,
    this.age,
    this.country,
  );

  @override
  List<Object?> get props => [name, username, password, age, country];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthProfileUpdateRequested extends AuthEvent {
  final String name;
  final String username;
  final int age;
  final String country;

  const AuthProfileUpdateRequested(
    this.name,
    this.username,
    this.age,
    this.country,
  );

  @override
  List<Object?> get props => [name, username, age, country];
}
