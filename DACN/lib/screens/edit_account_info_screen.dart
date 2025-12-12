import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_user.dart';

class EditAccountInfoScreen extends StatefulWidget {
  const EditAccountInfoScreen({super.key});

  @override
  _EditAccountInfoScreenState createState() => _EditAccountInfoScreenState();
}

class _EditAccountInfoScreenState extends State<EditAccountInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _userService = UserService();

  String? _userId;
  String _initialUsername = '';
  String _initialEmail = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        final decodedToken = JwtDecoder.decode(token);
        setState(() {
          _userId = decodedToken['_id'];
          _initialUsername = decodedToken['username'] ?? '';
          _initialEmail = decodedToken['email'] ?? '';
          _usernameController.text = _initialUsername;
          _emailController.text = _initialEmail;
          _isLoading = false;
        });
      } catch (e) {
        _showError("Error decoding user information.");
      }
    } else {
      _showError("Login information not found.");
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _userId == null) {
      return;
    }

    setState(() => _isSaving = true);

    final newUsername = _usernameController.text.trim();
    final newEmail = _emailController.text.trim();
    bool changed = false;
    String finalMessage = "Nothing changed.";
    if (newUsername != _initialUsername) {
      final result = await _userService.updateUsername(
        userId: _userId!,
        newUsername: newUsername,
      );
      changed = true;
      finalMessage = result['message'];
      if (result['success'] == true) {
        _initialUsername = newUsername;
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(finalMessage), backgroundColor: Colors.red),
        );
        return;
      }
    }
    if (newEmail != _initialEmail) {
      final result = await _userService.updateEmail(
        userId: _userId!,
        newEmail: newEmail,
      );
      changed = true;
      finalMessage = result['message'];
      if (result['success'] == true) {
        _initialEmail = newEmail;
      } else {

        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(finalMessage), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _isSaving = false);

    if (changed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(finalMessage), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Information"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveChanges,
                      icon: _isSaving
                          ? const SizedBox.shrink()
                          : const Icon(Icons.save_alt_outlined),
                      label: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}