import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegisterSuccess;
  final VoidCallback onNavigateToLogin;

  const RegisterScreen({
    super.key,
    required this.onRegisterSuccess,
    required this.onNavigateToLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  UserRole _selectedRole = UserRole.teen;
  String? _parentId;
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        parentId: _selectedRole == UserRole.teen ? _parentId : null,
      );
      
      widget.onRegisterSuccess();
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
        title: const Text('Register'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const FlutterLogo(size: 80),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem<UserRole>(
                    value: role,
                    child: Text(role.toString().split('.').last.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              if (_selectedRole == UserRole.teen) ...[
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Parent Email (optional)',
                    prefixIcon: Icon(Icons.family_restroom),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    _parentId = value.isEmpty ? null : value;
                  },
                ),
              ],
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
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Register',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onNavigateToLogin,
                child: const Text(
                  'Already have an account? Login',
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
