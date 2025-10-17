import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vraz_application/Student/Student_dashboard.dart';

import 'Admin/admin_dashboard_screen.dart';
import 'Parents/parents_dashboard.dart';
import 'Student/auth_models.dart';
import 'Teacher/Teacher_Dashboard_Screen.dart';
// --- Imports for Session Management & API Config ---
import 'api_config.dart';
import 'session_manager.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _otpSent = false;
  final TextEditingController _mobileController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _start = 30;

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

  Future<bool> _sendOtpApi(String phoneNumber) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/users/login/otp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phoneNumber}),
      );

      // A successful request might be 200 or 21 (Created)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        // Capture error message from the backend if available
        final responseBody = json.decode(response.body);
        _errorMessage = responseBody['message'] ?? 'Unknown error occurred.';
        return false;
      }
    } catch (e) {
      // --- FIX: Added a print statement for better debugging ---
      print("Error in _sendOtpApi: $e");
      _errorMessage = 'Network error. Please check your connection.';
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
        final responseBody = json.decode(response.body);
        _errorMessage = responseBody['message'] ?? 'Invalid OTP.';
        return null;
      }
    } catch (e) {
      // --- FIX: Added a print statement for better debugging ---
      print("Error in _verifyOtpApi: $e");
      _errorMessage = 'Network error. Please check your connection.';
      return null;
    }
  }

  void startTimer() {
    _start = 30;
    _timer?.cancel(); // Cancel any existing timer
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

    try {
      final sessionManager =
          Provider.of<SessionManager>(context, listen: false);
      final phoneNumber = _mobileController.text;

      final savedSession = await sessionManager.getSavedSession(phoneNumber);

      if (savedSession != null) {
        final user = savedSession['user'] as UserModel;
        final token = savedSession['token'] as String;
        await sessionManager.createSession(user, token, phoneNumber);

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const StudentDashboard()),
          (route) => false,
        );
      } else {
        // --- FIX: This is the main change ---
        // This now properly waits for the API call and handles the UI update.
        await _requestAndSendOtp();
      }
    } catch (e) {
      // Catch any unexpected errors during the process
      if (mounted) {
        setState(() {
          _errorMessage = "An unexpected error occurred: $e";
        });
      }
    } finally {
      // Ensure the loading indicator is always turned off
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestAndSendOtp() async {
    final success = await _sendOtpApi(_mobileController.text);
    if (!mounted) return;

    // This setState will now run regardless of success or failure,
    // ensuring the UI updates with either the OTP screen or an error message.
    setState(() {
      if (success) {
        _otpSent = true;
        startTimer();
      }
      // The _errorMessage is already set inside _sendOtpApi on failure
    });
  }

  void _verifyOtp() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit OTP.')),
      );
      return;
    }

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
        await sessionManager.createSession(user, token, phoneNumber);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const StudentDashboard()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = "Failed to process login data. Please try again.";
        });
      }
    }
    // The _errorMessage is set inside _verifyOtpApi on failure

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
        // --- FIX: Display error message here ---
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
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
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
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
              onPressed: _start == 0 ? _requestAndSendOtp : null,
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
