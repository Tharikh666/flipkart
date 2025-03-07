import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'account.dart'; // Import your account page

class LoginOTP extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  final String verificationId;

  const LoginOTP({
    super.key,
    required this.countryCode,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<LoginOTP> createState() => _LoginOTPState();
}

class _LoginOTPState extends State<LoginOTP> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;

  Future<void> verifyOTP() async {
    setState(() {
      isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpController.text.trim(),
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Account()),
        );
      }
    } catch (e) {
      print("Error verifying OTP: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid OTP. Please try again.")),
      );
    }

    setState(() {
      isLoading = false;
    });
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
          child: Icon(Icons.close, color: Colors.white),
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
      body: Column(
        children: [
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 15),
            child: RichText(
              textAlign: TextAlign.start,
              text: TextSpan(
                text: "Please enter the verification code we've sent you on ",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade900),
                children: [
                  TextSpan(
                    text: "${widget.countryCode}-${widget.phoneNumber} ",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Edit",
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 30),
          Pinput(
            controller: otpController,
            length: 6,
            autofocus: true,
            defaultPinTheme: PinTheme(
              width: 50,
              height: 50,
              textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: isLoading ? null : verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: CupertinoColors.activeBlue,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 14),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Verify",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
