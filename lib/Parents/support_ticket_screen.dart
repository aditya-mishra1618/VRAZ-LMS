import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vraz_application/Parents/service/support_ticket_service.dart';
import 'package:vraz_application/Parents/support_chat.dart';
import 'package:vraz_application/Parents/parent_app_drawer.dart';
import '../parent_session_manager.dart';
import 'models/support_ticket_model.dart';

class SupportTicketScreen extends StatefulWidget {
  const SupportTicketScreen({super.key});

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupportTicketService _ticketService = SupportTicketService();

  List<SupportTicketModel> _tickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🔷 [INIT] SupportTicketScreen initialized');
    // Load tickets after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔷 [INIT] Post frame callback - Loading tickets');
      _loadTickets();
    });
  }

  // ============================================
  // Load tickets from API (WITH DEBUGGING)
  // ============================================
  Future<void> _loadTickets() async {
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔵 [LOAD_TICKETS] Starting to load tickets...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    final sessionManager = Provider.of<ParentSessionManager>(context, listen: false);

    // 🔍 DEBUG: Print session details
    print('🔍 [SESSION_CHECK] Checking session manager...');
    print('   ├─ isLoggedIn: ${sessionManager.isLoggedIn}');
    print('   ├─ token exists: ${sessionManager.token != null}');
    print('   ├─ token length: ${sessionManager.token?.length ?? 0}');
    print('   ├─ currentParent: ${sessionManager.currentParent?.fullName ?? "NULL"}');
    print('   └─ phoneNumber: ${sessionManager.phoneNumber ?? "NULL"}');

    if (sessionManager.token != null && sessionManager.token!.isNotEmpty) {
      print('   ✅ Token first 30 chars: ${sessionManager.token!.substring(0, sessionManager.token!.length > 30 ? 30 : sessionManager.token!.length)}...');
    } else {
      print('   ❌ Token is NULL or EMPTY');
    }

    // Check if user is logged in
    if (!sessionManager.isLoggedIn || sessionManager.token == null) {
      print('❌ [AUTH_FAILED] User not logged in or token is null');
      setState(() {
        _errorMessage = 'Please login to view your support tickets.';
      });
      return;
    }

    print('✅ [AUTH_SUCCESS] User is logged in, proceeding with API call\n');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    print('🌐 [API_CALL] Calling fetchSupportTickets with token...');
    final response = await _ticketService.fetchSupportTickets(sessionManager.token!);
    print('🌐 [API_RESPONSE] Received response from API\n');

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success) {
          _tickets = response.data ?? [];
          print('✅ [SUCCESS] Tickets loaded successfully');
          print('   └─ Total tickets: ${_tickets.length}');
          if (_tickets.isNotEmpty) {
            print('\n📋 [TICKETS_LIST] Ticket details:');
            for (var i = 0; i < _tickets.length; i++) {
              print('   ${i + 1}. ID: ${_tickets[i].id} | Title: ${_tickets[i].title} | Status: ${_tickets[i].status}');
            }
          }
        } else {
          _errorMessage = response.errorMessage;
          print('❌ [ERROR] Failed to load tickets');
          print('   ├─ Error message: $_errorMessage');
          print('   └─ Status code: ${response.statusCode}');

          if (response.statusCode == 401) {
            print('🔐 [AUTH_EXPIRED] Token expired - handling session expiry');
            _handleSessionExpired(sessionManager);
          }
        }
      });
    }

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔵 [LOAD_TICKETS] Finished loading tickets');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  // ============================================
  // Handle session expired
  // ============================================
  void _handleSessionExpired(ParentSessionManager sessionManager) {
    print('⚠️ [SESSION_EXPIRED] Showing session expired dialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Your session has expired. Please login again.'),
        actions: [
          TextButton(
            onPressed: () async {
              print('🗑️ [CLEAR_SESSION] User clicked OK - Clearing session...');
              await sessionManager.clearSession();
              if (mounted) {
                print('🔄 [NAVIGATION] Closing dialog');
                Navigator.of(context).pop(); // Close dialog
                // TODO: Navigate to login screen
                // Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // Show error dialog
  // ============================================
  void _showErrorDialog(String title, String message) {
    print('⚠️ [ERROR_DIALOG] Showing error: $title - $message');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // Navigate to chat screen
  // ============================================
  void _navigateToChat(SupportTicketModel ticket) {
    print('💬 [NAVIGATION] Navigating to chat for ticket: ${ticket.title}');
    print('   └─ Ticket ID: ${ticket.id}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupportChatScreen(
          grievanceTitle: ticket.title,
          navigationSource: 'support_ticket_screen',
          ticketId: ticket.id, // ✅ ADD THIS LINE
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Support Tickets',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: () {
              print('🔄 [USER_ACTION] Refresh button clicked');
              _loadTickets();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: ParentAppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget()
          : _buildTicketsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          print('➕ [USER_ACTION] Raise Ticket button clicked');
          _showTicketModal(context);
        },
        label: const Text('Raise Ticket'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ============================================
  // Build error widget
  // ============================================
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: _errorMessage?.contains('login') == true
                  ? Colors.orange
                  : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                print('🔄 [USER_ACTION] Retry button clicked');
                _loadTickets();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Build tickets list
  // ============================================
  Widget _buildTicketsList() {
    return RefreshIndicator(
      onRefresh: () async {
        print('🔄 [USER_ACTION] Pull to refresh triggered');
        await _loadTickets();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Past Tickets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_tickets.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    'No tickets raised yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._tickets.map((ticket) => _buildTicketCard(ticket)),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Show modal for creating ticket
  // ============================================
  void _showTicketModal(BuildContext context) {
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📝 [RAISE_TICKET] Opening raise ticket modal');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    final sessionManager = Provider.of<ParentSessionManager>(context, listen: false);

    print('🔍 [SESSION_CHECK] Checking session before showing modal...');
    print('   ├─ isLoggedIn: ${sessionManager.isLoggedIn}');
    print('   ├─ token exists: ${sessionManager.token != null}');
    print('   └─ token length: ${sessionManager.token?.length ?? 0}');

    if (!sessionManager.isLoggedIn || sessionManager.token == null) {
      print('❌ [AUTH_FAILED] User not logged in - Showing error dialog');
      _showErrorDialog('Not Logged In', 'Please login to raise a support ticket.');
      return;
    }

    print('✅ [AUTH_SUCCESS] User authenticated - Opening modal\n');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return RaiseSupportTicketModal(
          onTicketCreated: () {
            print('🔄 [CALLBACK] Ticket created - Reloading tickets list');
            _loadTickets(); // Reload tickets after creation
          },
          authToken: sessionManager.token!,
        );
      },
    );
  }

  // ============================================
  // Build ticket card
  // ============================================
  Widget _buildTicketCard(SupportTicketModel ticket) {
    Color statusColor;
    Color statusBgColor;

    switch (ticket.status) {
      case 'RESOLVED':
        statusColor = Colors.green.shade700;
        statusBgColor = Colors.green.shade50;
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.blue.shade700;
        statusBgColor = Colors.blue.shade50;
        break;
      case 'PENDING':
        statusColor = Colors.orange.shade700;
        statusBgColor = Colors.orange.shade50;
        break;
      default:
        statusColor = Colors.grey.shade700;
        statusBgColor = Colors.grey.shade50;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        onTap: () => _navigateToChat(ticket),
        title: Text(
          ticket.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            ticket.initialMessage,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticket.userFriendlyStatus,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            if (ticket.canChat)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.blueAccent,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Modal for Raising New Support Ticket
// ============================================
class RaiseSupportTicketModal extends StatefulWidget {
  final VoidCallback onTicketCreated;
  final String authToken;

  const RaiseSupportTicketModal({
    super.key,
    required this.onTicketCreated,
    required this.authToken,
  });

  @override
  State<RaiseSupportTicketModal> createState() =>
      _RaiseSupportTicketModalState();
}

class _RaiseSupportTicketModalState extends State<RaiseSupportTicketModal> {
  final SupportTicketService _ticketService = SupportTicketService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  String? _selectedCategory = 'Academic';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    print('📝 [MODAL_INIT] Raise ticket modal initialized');
    print('   └─ Auth token length: ${widget.authToken.length}');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  // ============================================
  // Submit ticket to API (WITH DEBUGGING)
  // ============================================
  Future<void> _submitTicket() async {
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 [SUBMIT_TICKET] Starting ticket submission');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // Validation
    print('🔍 [VALIDATION] Validating form fields...');

    if (_titleController.text.trim().isEmpty) {
      print('❌ [VALIDATION_FAILED] Title is empty');
      _showSnackBar('Please enter a ticket title', Colors.red);
      return;
    }
    print('   ✅ Title: ${_titleController.text.trim()}');

    if (_detailsController.text.trim().isEmpty) {
      print('❌ [VALIDATION_FAILED] Details are empty');
      _showSnackBar('Please describe the issue in detail', Colors.red);
      return;
    }
    print('   ✅ Details: ${_detailsController.text.trim().substring(0, _detailsController.text.trim().length > 50 ? 50 : _detailsController.text.trim().length)}...');

    if (_selectedCategory == null) {
      print('❌ [VALIDATION_FAILED] Category not selected');
      _showSnackBar('Please select a category', Colors.red);
      return;
    }
    print('   ✅ Category: $_selectedCategory');
    print('✅ [VALIDATION_SUCCESS] All fields validated\n');

    setState(() => _isSubmitting = true);

    // Prepare request
    final fullTitle = '$_selectedCategory: ${_titleController.text.trim()}';
    final request = CreateSupportTicketRequest(
      title: fullTitle,
      initialMessage: _detailsController.text.trim(),
    );

    print('📦 [REQUEST] Preparing API request...');
    print('   ├─ Full title: $fullTitle');
    print('   ├─ Message length: ${_detailsController.text.trim().length}');
    print('   └─ Token length: ${widget.authToken.length}');

    // Call API
    print('🌐 [API_CALL] Calling createSupportTicket...');
    final response = await _ticketService.createSupportTicket(
      token: widget.authToken,
      request: request,
    );
    print('🌐 [API_RESPONSE] Received response\n');

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (response.success) {
      // Success
      print('✅ [SUCCESS] Ticket created successfully');
      print('   └─ Ticket ID: ${response.data?.id}');
      _showSnackBar('Ticket submitted successfully!', Colors.green);
      widget.onTicketCreated(); // Callback to refresh list
      Navigator.pop(context); // Close modal
      print('🔄 [NAVIGATION] Modal closed\n');
    } else {
      // Error
      print('❌ [ERROR] Failed to create ticket');
      print('   ├─ Error message: ${response.errorMessage}');
      print('   └─ Status code: ${response.statusCode}\n');

      _showSnackBar(
        response.errorMessage ?? 'Failed to submit ticket',
        Colors.red,
      );

      // Handle token expiry
      if (response.statusCode == 401) {
        print('🔐 [AUTH_EXPIRED] Token expired - Closing modal');
        Navigator.pop(context);
        // Session will be handled by parent screen
      }
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 [SUBMIT_TICKET] Finished ticket submission');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4F8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Raise New Ticket',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () {
                      print('❌ [USER_ACTION] Close button clicked - Modal dismissed');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDropdown(),
              const SizedBox(height: 20),
              _buildTitleField(),
              const SizedBox(height: 20),
              _buildDescriptionField(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category *', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: ['Academic', 'Payment', 'Attendance', 'Timetable', 'Other']
                .map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (newValue) {
              print('📝 [USER_INPUT] Category changed to: $newValue');
              setState(() {
                _selectedCategory = newValue;
              });
            },
            decoration: const InputDecoration(
              hintText: 'Select a category',
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ticket Title *',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'e.g., Unable to access course materials',
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Issue Details *',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _detailsController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Please describe the issue in detail...',
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitTicket,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBackgroundColor: Colors.grey.shade400,
      ),
      child: _isSubmitting
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
          : const Text(
        'Submit Ticket',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}