import 'package:drone_user_app/features/auth/bloc/auth_bloc.dart';
import 'package:drone_user_app/features/auth/screens/login_page.dart';
import 'package:drone_user_app/utils/helpers.dart';
import 'package:drone_user_app/utils/text_utils.dart';
import 'package:drone_user_app/widgets/custom_button.dart';
import 'package:drone_user_app/widgets/custom_text_field.dart';
import 'package:drone_user_app/wrapper_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final roles = ["Customer", "Pilot", "Service Center"];
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          } else if (state is Authenticated) {
            // When authentication is successful, dispatch navigation event
            context.read<AuthBloc>().add(NavigateToWrapper());
          } else if (state is NavigationRequested) {
            // Navigate to wrapper page when requested
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const WrapperPage()),
              (route) => false, // Clear all previous routes
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 100.h),
                        Text(
                          "Register",
                          style: TextUtils.kHeading(context),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 32.h),
                        Text(
                          "Register as",
                          style: TextUtils.kHeading(
                            context,
                          ).copyWith(fontSize: 18.sp),
                        ),
                        SizedBox(height: 8.h),
                        DropdownButtonFormField<String>(
                          items:
                              roles
                                  .map(
                                    (String role) => DropdownMenuItem<String>(
                                      value: role,
                                      child: Text(
                                        role,
                                        style: TextUtils.kBodyText(context),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedRole = value;
                            });
                          },
                          hint: Text("Select your role"),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.2.w,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return "Please select your role";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),
                        CustomTextField(
                          title: "Name",
                          hintText: "Enter your name",
                          controller: _nameController,
                          keyboardType: TextInputType.text,
                          obscureText: false,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        CustomTextField(
                          title: "Email",
                          hintText: "Enter your email",
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          obscureText: false,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            } else if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        CustomTextField(
                          title: "Password",
                          hintText: "Enter your password",
                          controller: _passwordController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            } else if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),
                        CustomButton(
                          text: "Register",
                          isOutlined: true,
                          height: 56.h,
                          onPressed: () {
                            final name = _nameController.text.trim();
                            final email = _emailController.text.trim();
                            final password = _passwordController.text.trim();
                            if (_formKey.currentState!.validate() &&
                                selectedRole != null) {
                              context.read<AuthBloc>().add(
                                RegisterEvent(
                                  name,
                                  email,
                                  password,
                                  selectedRole!,
                                ),
                              );
                            }
                          },
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account?",
                              style: TextUtils.kBodyText(context),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  Helpers.routeNavigation(context, LoginPage()),
                                );
                              },
                              child: Text(
                                "Login",
                                style: TextUtils.kBodyText(context).copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Always show progress indicator when loading
              if (state is AuthLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
