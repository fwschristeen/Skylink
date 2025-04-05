part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

class InitializeApp extends AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  LoginEvent(this.email, this.password);
}

class RegisterEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;

  RegisterEvent(this.name, this.email, this.password, this.role);
}

class LogoutEvent extends AuthEvent {}

class NavigateToWrapper extends AuthEvent {}

class AuthStateChanged extends AuthEvent {
  final User? user;

  AuthStateChanged(this.user);
}
