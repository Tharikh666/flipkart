import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final List<String> countryCodes = ['+91', '+1', '+44', '+61', '+971'];
  final TextEditingController phoneController = TextEditingController();
  bool isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(_validatePhoneNumber);
  }

  void _validatePhoneNumber() {
    setState(() {
      isButtonEnabled = phoneController.text.length == 10;
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.close,
            color: Colors.white,
          ),
        ),
        backgroundColor: CupertinoColors.activeBlue,
        centerTitle: true,
        title: Container(
          alignment: Alignment.center,
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icons/flipkart_logo_text.png'),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Log in for the best experience',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Enter your phone number to continue',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        autofocus: true,
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          labelStyle: TextStyle(color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue, width: 2),
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: countryCodes.first,
                                items: countryCodes.map((String code) {
                                  return DropdownMenuItem<String>(
                                    value: code,
                                    child: Text(
                                      code,
                                      style: TextStyle(fontSize: 16, color: Colors.black),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {},
                              ),
                            ),
                          ),
                          counterText: "", // Removes the character count indicator
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RichText(
                        text: TextSpan(
                          text:
                          "By Continuing, you confirm that you are above 18 years of age, and you agree to the Flipkart's ",
                          style: TextStyle(color: Colors.grey.shade900, fontSize: 16),
                          children: [
                            TextSpan(
                              text: "Terms of Use",
                              style: TextStyle(
                                color: CupertinoColors.activeBlue,
                                fontSize: 16,
                              ),
                            ),
                            TextSpan(
                              text: " and ",
                              style: TextStyle(color: Colors.grey.shade900, fontSize: 16),
                            ),
                            TextSpan(
                              text: "Privacy Policy",
                              style: TextStyle(
                                color: CupertinoColors.activeBlue,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isButtonEnabled ? () {} : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isButtonEnabled ? CupertinoColors.activeBlue : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            "Continue",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
