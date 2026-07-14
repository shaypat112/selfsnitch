import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onNavigateToRegister;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onNavigateToRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Save token and user info (in a real app, use secure storage)
      // For now, just call success callback
      widget.onLoginSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const FlutterLogo(size: 100),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Login',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onNavigateToRegister,
                child: const Text(
                  "Don't have an account? Register",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
