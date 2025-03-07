import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'account.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FocusNode nameFocus = FocusNode();
  final FocusNode addressFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  final _formKey = GlobalKey<FormState>();

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      User? user = userCredential.user;
      if (user != null) {
        String authId = user.uid;

        await FirebaseFirestore.instance
            .collection('userDetails')
            .doc(authId)
            .set({
          'name': nameController.text,
          'address': addressController.text,
          'email': emailController.text,
          'supercoin': 150,
          'authid': authId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User Signed up successfully."),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Account()),
        );
      }
    } catch (e) {
      print("Error during sign-up: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: CupertinoColors.activeBlue,
        centerTitle: true,
        title: Image.asset('assets/icons/flipkart_logo_text.png', height: 24),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign Up for the best experience',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enter your details to continue',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    SizedBox(height: 20),
                    buildTextField(
                        "Name", nameController, nameFocus, TextInputType.name),
                    SizedBox(height: 20),
                    buildTextField("Address", addressController, addressFocus,
                        TextInputType.streetAddress),
                    SizedBox(height: 20),
                    buildTextField("Email", emailController, emailFocus,
                        TextInputType.emailAddress),
                    SizedBox(height: 20),
                    buildTextField("Password", passwordController,
                        passwordFocus, TextInputType.visiblePassword,
                        obscureText: true),
                    SizedBox(height: 20),
                    buildTextField(
                        "Confirm Password",
                        confirmPasswordController,
                        confirmPasswordFocus,
                        TextInputType.visiblePassword,
                        obscureText: true),
                    SizedBox(height: 20),
                    RichText(
                      text: TextSpan(
                        text:
                            "By continuing, you confirm that you are above 18 years of age, and you agree to Flipkart's ",
                        style: TextStyle(
                            color: Colors.grey.shade900, fontSize: 16),
                        children: [
                          TextSpan(
                            text: "Terms of Use",
                            style: TextStyle(
                                color: CupertinoColors.activeBlue,
                                fontSize: 16),
                          ),
                          TextSpan(
                            text: " and ",
                            style: TextStyle(
                                color: Colors.grey.shade900, fontSize: 16),
                          ),
                          TextSpan(
                            text: "Privacy Policy",
                            style: TextStyle(
                                color: CupertinoColors.activeBlue,
                                fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CupertinoColors.activeBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          "Continue",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(
                        height: screenHeight * 0.05), // Ensures proper spacing
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      FocusNode focusNode, TextInputType inputType,
      {bool obscureText = false, int maxLength = 100}) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: inputType,
      obscureText: obscureText,
      maxLength: maxLength == 100 ? null : maxLength,
      textCapitalization: inputType == TextInputType.name ||
              inputType == TextInputType.streetAddress
          ? TextCapitalization.words
          : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "$label cannot be empty";
        }
        return null;
      },
    );
  }
}
