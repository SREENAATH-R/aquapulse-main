import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loginpage/features/user_auth/presentation/pages/login_page.dart';
import 'package:loginpage/features/user_auth/presentation/pages/verification_page.dart';
import 'package:loginpage/features/user_auth/presentation/widgets/form_container_widget.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _reenterPasswordController =
      TextEditingController();

  bool isSigningUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Aquapulse"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/lo.jpg',
                height: 80,
                width: 80,
              ),
              const SizedBox(height: 10),
              const Text(
                "Aquapulse",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              // Add your FormContainerWidget for each input field
              FormContainerWidget(
                controller: _usernameController,
                hintText: "Username",
                isPasswordField: false,
              ),
              const SizedBox(height: 10),
              FormContainerWidget(
                controller: _emailController,
                hintText: "Email",
                isPasswordField: false,
              ),
              const SizedBox(height: 10),
              FormContainerWidget(
                controller: _phoneController,
                hintText: "Phone No",
                isPasswordField: false,
              ),
              const SizedBox(height: 10),
              FormContainerWidget(
                controller: _taxIdController,
                hintText: "PAN NUMBER",
                isPasswordField: false,
              ),
              const SizedBox(height: 10),
              FormContainerWidget(
                controller: _taxIdController,
                hintText: "Location",
                isPasswordField: false,
              ),
              const SizedBox(height: 10),
              FormContainerWidget(
                controller: _passwordController,
                hintText: "Password",
                isPasswordField: true,
              ),
              const SizedBox(height: 10),
              FormContainerWidget(
                controller: _reenterPasswordController,
                hintText: "Re-enter Password",
                isPasswordField: true,
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  _signUp();
                },
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isSigningUp
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  const SizedBox(
                    width: 5,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _signUp() async {
    setState(() {
      isSigningUp = true;
    });

    String username = _usernameController.text;
    String email = _emailController.text;
    String phone = _phoneController.text;
    String taxId = _taxIdController.text;
    String password = _passwordController.text;
    String reenterPassword = _reenterPasswordController.text;

    if (password != reenterPassword) {
      // Handle password mismatch
      showToast(message: "Passwords do not match");
      setState(() {
        isSigningUp = false;
      });
      return;
    }

    try {
      // Create user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      // Store user data in Firestore
      await _storeUserDataInFirestore(
        userCredential.user?.uid ?? "",
        username,
        email,
        phone,
        taxId,
      );

      // Show success message
      showToast(message: "Verification email sent. Please verify your email.");

      // Navigate to verification page or any other page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationPage(email: email),
        ),
      );
    } catch (e) {
      // Handle signup error
      showToast(message: "Error: $e");
    } finally {
      setState(() {
        isSigningUp = false;
      });
    }
  }

  Future<void> _storeUserDataInFirestore(String userId, String username,
      String email, String phone, String taxId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'username': username,
        'email': email,
        'phone': phone,
        'taxId': taxId,
      });
      print('User data stored in Firestore');
    } catch (e) {
      print('Error storing user data in Firestore: $e');
    }
  }

  // You can replace this showToast function with your own implementation
  void showToast({required String message}) {
    // Implement your toast logic here
    print(message);
  }
}
