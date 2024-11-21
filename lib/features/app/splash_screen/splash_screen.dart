import 'package:flutter/material.dart';
// Import your user login page
// Import your admin login page

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: const Text("User"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/adminLogin');
              },
              child: const Text("Admin"),
            ),
          ],
        ),
      ),
    );
  }
}
