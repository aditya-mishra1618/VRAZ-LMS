import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vraz_application/Student/Student_dashboard_screen.dart';
import 'package:vraz_application/parent_session_manager.dart';
import 'package:vraz_application/teacher_session_manager.dart';

import 'Admin/admin_dashboard_screen.dart';
import 'Parents/models/parent_model.dart';
import 'Parents/parents_dashboard.dart';
import 'Student/models/auth_models.dart';
import 'Teacher/Teacher_Dashboard_Screen.dart';
import 'Teacher/models/teacher_model.dart';
import 'Teacher/services/login_api.dart';
import 'api_config.dart';
import 'student_session_manager.dart';
import 'universal_notification_service.dart';

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
  Future<void> _credentialLoginApi(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    debugPrint('[DEBUG] Attempting login for $email');

    try {
      final response = await LoginApiService.credentialLogin(email, password);

      debugPrint('[DEBUG] Login API response: $response');

      if (response != null && response['token'] != null) {
        final teacher = TeacherModel.fromJson(response['user']);
        final token = response['token'];

        debugPrint(
            '[DEBUG] Login successful. Token: $token, User: ${teacher.email}');

        // Save session
        final sessionManager = TeacherSessionManager();
        await sessionManager.saveSession(teacher, token);

        if (!mounted) return;

        // Navigate to Teacher Dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
              (route) => false,
        );
      } else {
        debugPrint('[ERROR] Login failed. Response: $response');
        setState(() {
          _errorMessage = response != null
              ? response['message']
              : 'Login failed. Try again.';
        });
      }
    } catch (e, stack) {
      debugPrint('[ERROR] Exception during login: $e');
      debugPrint('[STACKTRACE] $stack');
      setState(() {
        _errorMessage = 'Login failed due to an exception. See debug logs.';
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

  void _handleOtpLoginAttempt() async {
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

    final phoneNumber = _mobileController.text;

    // Handle Student Login
    if (widget.role == 'Student') {
      final sessionManager = Provider.of<SessionManager>(context, listen: false);
      final savedSession = await sessionManager.getSavedSession(phoneNumber);

      if (savedSession != null) {
        final user = savedSession['user'] as UserModel;
        final token = savedSession['token'] as String;
        await sessionManager.createSession(user, token, phoneNumber);

        // ✅ Register FCM token for saved session
        await UniversalNotificationService.instance.registerStudentDevice(
          authToken: token,
        );
        debugPrint('[Student] ✅ FCM token registered for saved session');

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboard()),
              (route) => false,
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    // Handle Parent Login
    if (widget.role == 'Parent') {
      final parentSessionManager = Provider.of<ParentSessionManager>(context, listen: false);
      final savedSession = await parentSessionManager.getSavedSession(phoneNumber);

      if (savedSession != null) {
        final parent = savedSession['parent'] as ParentModel;
        final token = savedSession['token'] as String;
        await parentSessionManager.createSession(parent, token, phoneNumber);

        // ✅ Register FCM token for saved session
        await UniversalNotificationService.instance.registerParentDevice(
          authToken: token,
        );
        debugPrint('[Parent] ✅ FCM token registered for saved session');

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
              (route) => false,
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    // Send OTP (same API for both Student and Parent)
    final success = await _sendOtpApi(phoneNumber);
    if (!mounted) return;
    setState(() {
      if (success) {
        _otpSent = true;
        startTimer();
      } else {
        _errorMessage = "Failed to send OTP. Please try again.";
      }
      _isLoading = false;
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
        // Handle Student Login
        if (widget.role == 'Student') {
          final user = UserModel.fromJson(responseData['user']);
          final token = responseData['token'];
          final sessionManager =
          Provider.of<SessionManager>(context, listen: false);
          await sessionManager.createSession(user, token, phoneNumber);

          // ✅ Register FCM token after OTP verification
          await UniversalNotificationService.instance.registerStudentDevice(
            authToken: token,
          );
          debugPrint('[Student] ✅ FCM token registered after login');

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const StudentDashboard()),
                (route) => false,
          );
        }
        // Handle Parent Login
        else if (widget.role == 'Parent') {
          final parent = ParentModel.fromJson(responseData['user']);
          final token = responseData['token'];
          final parentSessionManager =
          Provider.of<ParentSessionManager>(context, listen: false);
          await parentSessionManager.createSession(parent, token, phoneNumber);

          // ✅ Register FCM token after OTP verification
          await UniversalNotificationService.instance.registerParentDevice(
            authToken: token,
          );
          debugPrint('[Parent] ✅ FCM token registered after login');

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
                (route) => false,
          );
        }
      } catch (e) {
        debugPrint('[ERROR] Failed to process login: $e');
        if (!mounted) return;
        setState(() {
          _errorMessage = "Failed to process login data. Please try again.";
        });
      }
    } else {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Invalid OTP. Please try again.";
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
      final response = await LoginApiService.credentialLogin(email, password);
      debugPrint('[DEBUG] API Response: $response');

      if (response == null) {
        debugPrint('[ERROR] Response is null');
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
        });
        return;
      }

      if (response['token'] == null || response['user'] == null) {
        debugPrint('[ERROR] Token or user missing in response');
        setState(() {
          _errorMessage = response['message'] ?? 'Login failed.';
        });
        return;
      }

      // Parse user and save session
      final teacher = TeacherModel.fromJson(response['user']);
      final token = response['token'];

      debugPrint('[DEBUG] Login successful. Saving session...');
      final sessionManager = Provider.of<TeacherSessionManager>(context, listen: false);
      await sessionManager.saveSession(teacher, token);
      debugPrint('[DEBUG] Token saved: $token, User: ${teacher.fullName}');
      print('\n\n');
      print('╔════════════════════════════════════════════════════════════╗');
      print('║              🔐 TEACHER LOGIN SUCCESSFUL                   ║');
      print('╠════════════════════════════════════════════════════════════╣');
      print('║                     AUTH TOKEN:                            ║');
      print('╠════════════════════════════════════════════════════════════╣');
      print('║ $token');
      print('╠════════════════════════════════════════════════════════════╣');
      print('║ Token Length: ${token.length}');
      print('╚════════════════════════════════════════════════════════════╝');
      print('\n\n');
      await UniversalNotificationService.instance.registerTeacherDevice(
        authToken: token,
      );
      debugPrint('[Teacher] ✅ FCM token registered after login');
      if (!mounted) return;

      // Navigate based on role
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
      debugPrint('[ERROR] Exception during login: $e');
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

  // Mobile Input for OTP roles
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
            onPressed: _handleOtpLoginAttempt,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A65F8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
                widget.role == 'Student' || widget.role == 'Parent'
                    ? 'Continue'
                    : 'Send OTP',
                style: const TextStyle(fontSize: 16, color: Colors.white)
            ),
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
          if (value.isNotEmpty && index < 5)
            _focusNodes[index + 1].requestFocus();
          if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
        },
      ),
    );
  }

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
}