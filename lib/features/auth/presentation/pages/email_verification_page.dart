import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/email_verification_form.dart';

class EmailVerificationPage extends StatelessWidget {
  final String email;

  const EmailVerificationPage({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Email'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocProvider<AuthBloc>(
        create: (context) => GetIt.instance<AuthBloc>(),
        child: EmailVerificationForm(email: email),
      ),
    );
  }
} 