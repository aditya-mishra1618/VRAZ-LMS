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
  // --- State Variables for OTP Flow ---
  bool _otpSent = false;
  final TextEditingController _mobileController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _start = 30;

  // --- State Variables for Credential Flow ---
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // --- Common State Variables ---
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _mobileController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
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
    // ... (This function remains unchanged)
    final url = Uri.parse('${ApiConfig.baseUrl}/api/users/login/otp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phoneNumber}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return true;
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _verifyOtpApi(String phone, String otp) async {
    // ... (This function remains unchanged)
    final url = Uri.parse('${ApiConfig.baseUrl}/api/users/verify/otp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phone, 'otp': otp}),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- NEW: Dummy API for Teacher/Admin Login ---
  Future<Map<String, dynamic>?> _credentialLoginApi(
      String userId, String password) async {
    // TODO: Replace this with your actual User ID/Password login API call.
    print(
        "Attempting dummy credential login for User ID: $userId, Password: $password");
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    // Simulate a successful login if password is "password"
    if (password == "password") {
      // Return a user object similar to the OTP response
      return {
        "message": "Login successful",
        "token": "DUMMY_TOKEN_FOR_${widget.role.toUpperCase()}",
        "user": {
          "id": "dummy_${widget.role.toLowerCase()}_id",
          "fullName": "Dummy ${widget.role}",
          "email": "${widget.role.toLowerCase()}@example.com",
          "role": widget.role.toLowerCase(),
          "permissions": {}, // Add dummy permissions if needed
          "admissionId": null
        }
      };
    } else {
      _errorMessage = "Invalid User ID or Password.";
      return null;
    }
  }

  // --- Logic Handlers ---

  void startTimer() {
    // ... (This function remains unchanged)
    _start = 30;
    _timer?.cancel();
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
    // ... (This function remains unchanged)
    if (_mobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number.')));
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final sessionManager = Provider.of<SessionManager>(context, listen: false);
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
          (route) => false);
    } else {
      await _requestAndSendOtp();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestAndSendOtp() async {
    // ... (This function remains unchanged)
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
    // ... (This function remains unchanged)
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter the complete 6-digit OTP.')));
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
            (route) => false);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = "Failed to process login data. Please try again.";
        });
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- MODIFIED: Dummy login is now just for Parents ---
  void _dummyParentLogin() {
    if (_mobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid 10-digit mobile number.')),
      );
      return;
    }
    // For parents, we just simulate the OTP screen without a real API call
    setState(() {
      _otpSent = true;
      startTimer();
    });
  }

  void _dummyParentVerify() {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 6) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ParentDashboardScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit OTP.')),
      );
    }
  }

  // --- NEW: Logic handler for Teacher/Admin credential login ---
  void _handleCredentialLogin() async {
    if (_userIdController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both User ID and Password.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final responseData = await _credentialLoginApi(
        _userIdController.text, _passwordController.text);

    if (responseData != null && mounted) {
      Widget destination;
      switch (widget.role) {
        case 'Teacher':
          destination = const TeacherDashboardScreen();
          break;
        case 'Admin':
          destination = const AdminDashboardScreen();
          break;
        default:
          return; // Should not happen
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => destination),
        (route) => false,
      );
    }

    // Error message is set inside the API call
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine which UI to show based on the role
    final isOtpRole = widget.role == 'Student' || widget.role == 'Parent';
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
                  if (_otpSent && isOtpRole) {
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
                child: isOtpRole
                    ? (_otpSent ? _buildOtpView() : _buildMobileView())
                    : _buildCredentialView(),
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

  // UI for Student / Parent (Mobile Number)
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
            onPressed: widget.role == 'Student'
                ? _handleStudentLoginAttempt
                : _dummyParentLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A65F8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(widget.role == 'Student' ? 'Continue' : 'Send OTP',
                style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // UI for OTP Verification
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
            child: Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14)),
          ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Didn't receive code? "),
            TextButton(
              onPressed: _start == 0
                  ? (widget.role == 'Student'
                      ? _requestAndSendOtp
                      : _dummyParentLogin)
                  : null,
              child: Text(_start == 0 ? 'Resend OTP' : 'Resend in $_start s'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                widget.role == 'Student' ? _verifyOtp : _dummyParentVerify,
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

  // NEW: UI for Teacher / Admin (User ID & Password)
  Column _buildCredentialView() {
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
          controller: _userIdController,
          decoration: InputDecoration(
            hintText: 'User ID',
            prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14)),
          ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleCredentialLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A65F8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Login',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  SizedBox _buildOtpBox(int index) {
    // ... (This widget remains unchanged)
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
