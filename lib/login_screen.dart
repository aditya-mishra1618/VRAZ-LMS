import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vraz_application/Student/Student_dashboard.dart';

import 'Parents/Teacher/Teacher_Dashboard_Screen.dart';
import 'Parents/parents_dashboard.dart';
import 'Student/auth_models.dart';
import 'admin_dashboard_screen.dart';
// --- Imports for Session Management & API Config ---
import 'api_config.dart';
import 'session_manager.dart';

// This file combines the UI you provided (with separate OTP boxes)
// with the advanced login logic (remembering student logins).

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- State Variables from your UI ---
  bool _otpSent = false;
  final TextEditingController _mobileController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _start = 30;

  // --- State Variables for API and Session Handling ---
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _mobileController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  // --- API Methods ---

  Future<bool> _sendOtpApi(String phoneNumber) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/users/login/otp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phoneNumber}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _verifyOtpApi(String phone, String otp) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/users/verify/otp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phone, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // --- Logic Handlers ---

  void startTimer() {
    _start = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_start == 0) {
        setState(() => timer.cancel());
      } else {
        setState(() => _start--);
      }
    });
  }

  /// This is now the main entry point for the student login button.
  void _handleStudentLoginAttempt() async {
    if (_mobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid 10-digit mobile number.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final sessionManager = Provider.of<SessionManager>(context, listen: false);
    final phoneNumber = _mobileController.text;

    // 1. Check for a saved session for this phone number
    final savedSession = await sessionManager.getSavedSession(phoneNumber);

    if (savedSession != null) {
      // --- DIRECT LOGIN FLOW ---
      print("Found saved session for $phoneNumber. Logging in directly.");
      final user = savedSession['user'] as UserModel;
      final token = savedSession['token'] as String;

      // Reactivate the session by calling createSession again
      await sessionManager.createSession(user, token, phoneNumber);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const StudentDashboard()),
        (route) => false,
      );
    } else {
      // --- OTP FLOW (for new or unrecognized numbers) ---
      print("No saved session for $phoneNumber. Proceeding with OTP.");
      await _requestAndSendOtp();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// This method now ONLY handles the API call and UI update for sending an OTP.
  Future<void> _requestAndSendOtp() async {
    final success = await _sendOtpApi(_mobileController.text);
    if (!mounted) return;
    setState(() {
      if (success) {
        _otpSent = true;
        startTimer();
      } else {
        _errorMessage = "Failed to send OTP. Please try again.";
      }
    });
  }

  void _verifyOtp() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 6) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final phoneNumber = _mobileController.text;
      final responseData = await _verifyOtpApi(phoneNumber, otp);

      if (responseData != null && mounted) {
        try {
          final user = UserModel.fromJson(responseData['user']);
          final token = responseData['token'];

          final sessionManager =
              Provider.of<SessionManager>(context, listen: false);
          // Create the session for the first time, linking it to the phone number
          await sessionManager.createSession(user, token, phoneNumber);

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const StudentDashboard()),
            (route) => false,
          );
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage =
                "An error occurred. Please check the data and try again.";
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = "Invalid OTP. Please try again.";
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit OTP.')),
      );
    }
  }

  // --- Dummy Login for Non-Student Roles ---
  void _dummyLogin() {
    if (_mobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid 10-digit mobile number.')),
      );
      return;
    }

    Widget destination;
    switch (widget.role) {
      case 'Parent':
        destination = const ParentDashboardScreen();
        break;
      case 'Teacher':
        destination = const TeacherDashboardScreen();
        break;
      case 'Admin':
        destination = const AdminDashboardScreen();
        break;
      default:
        return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.role == 'Student';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: _isLoading
              ? null
              : () {
                  if (_otpSent && isStudent) {
                    setState(() {
                      _otpSent = false;
                      _timer?.cancel();
                      _errorMessage = null;
                    });
                  } else {
                    Navigator.of(context).pop();
                  }
                },
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: _otpSent && isStudent
                    ? _buildOtpView()
                    : _buildMobileView(),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // This is the UI you provided for entering the mobile number.
  Column _buildMobileView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Welcome to VRaZ',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Login as a ${widget.role}',
            style: const TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 48),
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: InputDecoration(
            hintText: 'Mobile Number',
            prefixIcon:
                const Icon(Icons.phone_android_outlined, color: Colors.grey),
            prefixText: '+91 | ',
            prefixStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            counterText: "",
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            // This button now contains the logic to check for a saved user before sending an OTP.
            onPressed: widget.role == 'Student'
                ? _handleStudentLoginAttempt
                : _dummyLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A65F8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(widget.role == 'Student' ? 'Continue' : 'Login',
                style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // This is the UI for OTP entry with 6 boxes, as requested.
  Column _buildOtpView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Enter Verification Code',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          'We have sent the OTP to +91 ${_mobileController.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) => _buildOtpBox(index)),
        ),
        const SizedBox(height: 20),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Didn't receive code? "),
            TextButton(
              onPressed: _start == 0 ? () => _requestAndSendOtp() : null,
              child: Text(_start == 0 ? 'Resend OTP' : 'Resend in $_start s'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A65F8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Verify OTP',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  SizedBox _buildOtpBox(int index) {
    return SizedBox(
      width: 50,
      height: 50,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
