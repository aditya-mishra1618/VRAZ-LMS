import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vraz_application/Student/Student_dashboard_screen.dart';
import 'package:vraz_application/teacher_session_manager.dart';

import 'Admin/admin_dashboard_screen.dart';
import 'Parents/parents_dashboard.dart';
import 'Student/models/auth_models.dart';
import 'Teacher/Teacher_Dashboard_Screen.dart';
// --- Imports for API Config ---
import 'Teacher/models/teacher_model.dart';
import 'Teacher/services/login_api.dart'; // Make sure this path is correct
import 'api_config.dart';
import 'student_session_manager.dart';

// --- Placeholder for your Notification Service ---
// You will need to import your actual notification service here
// e.g., import 'services/notification_service.dart';

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
    for (var c in _otpControllers) c.dispose();
    for (var n in _focusNodes) n.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ==================== OTP APIs ========================
  Future<bool> _sendOtpApi(String phoneNumber) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/users/login/otp');
    try {
      debugPrint('[DEBUG] Sending OTP to $phoneNumber');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phoneNumber}),
      );
      debugPrint(
          '[DEBUG] OTP API response: ${response.statusCode} ${response.body}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('[ERROR] OTP send failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _verifyOtpApi(String phone, String otp) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/users/verify/otp');
    try {
      debugPrint('[DEBUG] Verifying OTP $otp for $phone');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phone, 'otp': otp}),
      );
      debugPrint(
          '[DEBUG] OTP Verify response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) {
      debugPrint('[ERROR] OTP verification failed: $e');
      return null;
    }
  }

  // ==================== Teacher/Admin Credential API ====================
  // This function is in `login_api.dart`, this is just a placeholder
  // to match the code in your file.
  // Future<void> _credentialLoginApi(String email, String password) async {
  //   ...
  // }

  // ==================== Logic Handlers ====================
  void startTimer() {
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

  /// Handles sending the OTP for a new student
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

  /// Handles the "Continue" button press for Students.
  /// Checks for a saved session, or sends an OTP if none is found.
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
    final savedSession = await sessionManager.getSavedSession(phoneNumber);

    if (savedSession != null) {
      // Saved session found, check the role.
      final user = savedSession['user'] as UserModel;
      final token = savedSession['token'] as String;

      // Check if the saved role matches the selected role on the UI
      if (user.role.toLowerCase() == widget.role.toLowerCase()) {
        // Role matches, log in directly
        await sessionManager.createSession(user, token, phoneNumber);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboard()),
          (route) => false,
        );
      } else {
        // Role does NOT match, show an error
        setState(() {
          _errorMessage = "You are not registered as a ${widget.role}.";
          _isLoading = false; // Stop loading
        });
        return; // Stop the login attempt
      }
    } else {
      // No saved session, proceed with OTP flow
      await _requestAndSendOtp();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Handles the "Send OTP" button for Parents (Dummy Flow)
  void _handleParentLoginAttempt() async {
    if (_mobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid 10-digit mobile number.')),
      );
      return;
    }

    // Simulate sending OTP for parent
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _otpSent = true;
      startTimer();
    });
  }

  /// Verifies the OTP for Students (Real API)
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
          MaterialPageRoute(builder: (_) => const StudentDashboard()),
          (route) => false,
        );
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

  /// Verifies the OTP for Parents (Dummy Flow)
  void _dummyParentVerify() {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit OTP.')),
      );
      return;
    }
    // Any 6-digit OTP works for the dummy parent login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
      (route) => false,
    );
  }

  // ==================== THIS IS THE FIXED FUNCTION ====================
  void _handleCredentialLogin() async {
    final email = _userIdController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both Email and Password.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    debugPrint('[DEBUG] Initiating login for: $email');

    try {
      // 1. API Login (This part is succeeding)
      final response = await LoginApiService.credentialLogin(email, password);
      debugPrint('[DEBUG] API Response: $response');

      if (response == null) {
        debugPrint('[ERROR] Response is null');
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
          _isLoading = false; // Stop loading
        });
        return;
      }

      if (response['token'] == null || response['user'] == null) {
        debugPrint('[ERROR] Token or user missing in response');
        setState(() {
          _errorMessage = response['message'] ?? 'Login failed.';
          _isLoading = false; // Stop loading
        });
        return;
      }

      // 2. Parse user and save session (This is also succeeding)
      final teacher = TeacherModel.fromJson(response['user']);
      final token = response['token'];

      debugPrint('[DEBUG] Login successful. Saving session...');
      await TeacherSessionManager().saveSession(teacher, token);
      debugPrint('[DEBUG] Token saved: $token, User: ${teacher.fullName}');

      // --- START OF FIX ---
      // This is where your log shows the "Registering Teacher device"
      // and the "firebase_messaging" error.
      // We wrap this notification logic in its own try/catch block.
      try {
        debugPrint('[UNS] 📱 Registering Teacher device...');
        // Replace this with your actual notification service call.
        // e.g., await YourNotificationService.registerDevice(token);
        // This is just a placeholder to represent the failing code.
        if (token.isNotEmpty) {
          print(
              "Attempting to register for notifications (this will likely fail on web/localhost but won't stop login)");
          // Example of what might be failing:
          // await FirebaseMessaging.instance.getToken();
        }
      } catch (notificationError) {
        // Log the error but DO NOT stop the login
        debugPrint(
            '[ERROR] Failed to register for notifications, but proceeding with login: $notificationError');
      }
      // --- END OF FIX ---

      if (!mounted) return;

      // 3. Navigate (This part will now be reached)
      Widget destination;
      switch (widget.role) {
        case 'Teacher':
          destination = const TeacherDashboardScreen();
          break;
        case 'Admin':
          destination = const AdminDashboardScreen();
          break;
        default:
          debugPrint('[ERROR] Unknown role: ${widget.role}');
          setState(() {
            _errorMessage = 'Unknown user role.';
          });
          return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } catch (e, stack) {
      // This will now only catch critical LOGIN errors,
      // not notification errors.
      debugPrint('[ERROR] Exception during main login: $e');
      debugPrint('[STACKTRACE] $stack');
      setState(() {
        _errorMessage = 'Login failed due to an exception. Check debug logs.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // ==================== END OF FIXED FUNCTION ====================

  // ==================== UI Components ====================
  @override
  Widget build(BuildContext context) {
    final isOtpRole = widget.role == 'Student' || widget.role == 'Parent';

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

  // Mobile Input for OTP roles (Student and Parent)
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
        // --- This is where the error message will appear ---
        if (_errorMessage != null && !_otpSent)
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
            // --- FIX ---
            // This now correctly routes to the Student or Parent login handlers.
            onPressed: widget.role == 'Student'
                ? _handleStudentLoginAttempt
                : _handleParentLoginAttempt,
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

  // OTP Verification view (Student and Parent)
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
              // --- FIX ---
              // Correctly routes to the real or dummy "resend" logic.
              onPressed: _start == 0
                  ? (widget.role == 'Student'
                      ? _requestAndSendOtp
                      : _handleParentLoginAttempt)
                  : null,
              child: Text(_start == 0 ? 'Resend OTP' : 'Resend in $_start s'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            // --- FIX ---
            // Correctly routes to the real or dummy "verify" logic.
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

  // Credential Input view (Teacher and Admin)
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
            hintText: 'Email',
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
                style: const TextStyle(fontSize: 16, color: Colors.white)),
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
          if (value.isNotEmpty && index < 5)
            _focusNodes[index + 1].requestFocus();
          if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
        },
      ),
    );
  }
}
