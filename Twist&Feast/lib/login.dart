import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/main_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // Kontroleri za unos podataka
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  Future<void> saveGlobalUid() async {
    if (globalUid != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('globalUid', globalUid!);
    }
  }

  void showPasswordResetDialog(BuildContext context) {
    final _emailController = TextEditingController();
    bool _isLoading = false;
    String? _errorMessage;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Password',
          style: TextStyle(color: Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16.0),
            if (_isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () async {
                  final email = _emailController.text.trim();
                  if (email.isEmpty) {
                    setState(() {
                      _errorMessage = 'Please enter your email address.';
                    });
                    return;
                  }

                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    await FirebaseAuth.instance
                        .sendPasswordResetEmail(email: email);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password reset email sent!')),
                    );
                  } on FirebaseAuthException catch (e) {
                    setState(() {
                      if (e.code == 'invalid-email') {
                        _errorMessage = 'Invalid email address.';
                      } else if (e.code == 'user-not-found') {
                        _errorMessage = 'No user found for that email.';
                      } else {
                        _errorMessage = 'An unexpected error occurred.';
                      }
                    });
                  } catch (e) {
                    _errorMessage = 'An unexpected error occurred.';
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                child: Text(
                  'Reset Password',
                  style: TextStyle(color: Colors.black),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> signUserIn() async {
    //  loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
      }

      globalUid = userCredential.user?.uid;
      await saveGlobalUid();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in successfully!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainMenuPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }

      print('FirebaseAuthException: ${e.code} - ${e.message}');

      String message;
      switch (e.code) {
        case 'user-not-found':
          message =
              'No user found for that email. Please check the email address.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided. Please check your password.';
          break;
        case 'invalid-email':
          message =
              'The email address is not valid. Please check the email address.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password. Please check your credentials.';
          break;
        default:
          print('Unhandled FirebaseAuthException: ${e.code} - ${e.message}');
          message = 'An error occurred. Please try again.';
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }

      print('Unknown error: $e');

      // Show a general error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An unknown error occurred. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color.fromRGBO(
          183, 173, 172, 1), // Svetlo siva pozadina, // Tamna pozadina

      body: Padding(
        padding: const EdgeInsets.only(top: 120, right: 16, left: 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Povećana slika igre
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Image.asset(
                  'assets/logo.png',
                  height: 180,
                ),
              ),

              // Polje za email
              TextFormField(
                controller: _emailController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),

              // Polje za lozinku
              TextFormField(
                controller: _passwordController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  } else if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),

              // Opcija za zaboravljenu lozinku
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Forgot Password?')),
                  );
                  showPasswordResetDialog(context);
                },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.white),
                ),
              ),

              // Dugme za prijavu
              Container(
                width: 200,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.lightGreenAccent],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await signUserIn();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Log In',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),

              SizedBox(height: 20),

              SizedBox(height: 30),

              Text(
                "Don't have an account?",
                style: TextStyle(color: Colors.white),
              ),

              SizedBox(height: 10),

              // Dugme za registraciju
              Container(
                width: 200,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return RegisterPage();
                      }),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Register',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
