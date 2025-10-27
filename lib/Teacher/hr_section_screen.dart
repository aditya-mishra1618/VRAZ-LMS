import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import your necessary files (adjust paths as needed)
// Make sure these paths are correct for your project structure
import '../teacher_session_manager.dart'; // For getting the auth token
import 'models/leave_application_model.dart'; // Import the updated model
import 'services/leave_api_service.dart'; // Import the new API service
import 'teacher_app_drawer.dart'; // Your app drawer

class HRSectionScreen extends StatefulWidget {
  const HRSectionScreen({super.key});

  @override
  State<HRSectionScreen> createState() => _HRSectionScreenState();
}

class _HRSectionScreenState extends State<HRSectionScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // API Service
  final LeaveApiService _leaveApiService = LeaveApiService();

  // State
  String? _authToken; // Store the token
  int _sickLeavesTaken = 0;
  int _casualLeavesTaken = 0;
  int _unpaidLeavesTaken = 0; // Counts APPROVED leaves deducted as UNPAID
  final int _totalSickLeaves = 10; // Fixed quota
  final int _totalCasualLeaves = 10; // Fixed quota
  final int _totalUnpaidLeaves = 0; // No quota for unpaid

  List<LeaveApplication> _leaveApplications = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeAndFetchLeaves();
    });
  }

  // Get token and perform initial fetch
  Future<void> _initializeAndFetchLeaves() async {
    // --- Using TeacherSessionManager ---
    final sessionManager = TeacherSessionManager();
    final session = await sessionManager.getSession();

    if (session == null ||
        session['token'] == null ||
        (session['token'] as String).isEmpty) {
      print('[ERROR] No session found in HR screen.');
      if (mounted) {
        setState(() {
          _errorMessage =
              "Authentication token not found. Please log in again.";
          _isLoading = false;
        });
      }
      return;
    }
    _authToken = session['token'] as String;

    if (_authToken!.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = "Authentication token is empty. Please log in again.";
          _isLoading = false;
        });
      }
      return;
    }

    print('HR Screen: Auth Token found.');
    await _fetchLeaves();
  }

  // Fetch leaves from API and update balance
  Future<void> _fetchLeaves() async {
    if (_authToken == null) return; // Guard against null token

    // Show loading only if not already deleting
    // Use mounted check before setState
    if (!_isDeleting && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final leaves = await _leaveApiService.getMyLeaves(_authToken!);
      if (mounted) {
        // Calculate balance based on the newly fetched leaves *before* setState
        final balance = _calculateLeaveBalance(leaves);
        // Update state with leaves and calculated balance simultaneously
        setState(() {
          _leaveApplications = leaves;
          _sickLeavesTaken = balance.sick;
          _casualLeavesTaken = balance.casual;
          _unpaidLeavesTaken = balance.unpaid;
          _isLoading = false;
          _isDeleting = false; // Reset delete flag after successful fetch
        });
        print(
            'Fetch successful, UI updated. Balance: Sick=$_sickLeavesTaken, Casual=$_casualLeavesTaken, Unpaid=$_unpaidLeavesTaken');
      }
    } catch (e) {
      print('Error setting leave state: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          _isDeleting = false; // Reset delete flag on error too
        });
      }
    }
  }

  // Calculate leave balance from fetched data - Returns a record for clarity
  ({int sick, int casual, int unpaid}) _calculateLeaveBalance(
      List<LeaveApplication> leaves) {
    int sickTaken = 0;
    int casualTaken = 0;
    int unpaidTaken = 0;

    for (var leave in leaves) {
      // Only count APPROVED leaves towards balance
      if (leave.status == 'APPROVED') {
        // Calculate duration inclusively
        int duration = leave.endDate.difference(leave.startDate).inDays + 1;
        if (duration < 1) duration = 1; // Ensure minimum 1 day

        // Categorize based on deductedAs
        switch (leave.deductedAs.toUpperCase()) {
          // Use uppercase for safety
          case 'SICK':
            sickTaken += duration;
            break;
          case 'CASUAL':
            casualTaken += duration;
            break;
          case 'UNPAID':
            unpaidTaken += duration;
            break;
          default:
            // If deductedAs is null or empty for an approved leave, maybe count as unpaid?
            // Or log it as unexpected. For now, we only count explicitly marked UNPAID.
            print(
                "Approved leave ID ${leave.id} has unexpected/missing deductedAs: ${leave.deductedAs}");
            break;
        }
      }
    }
    print(
        'Leave Balance Calculated: Sick=$sickTaken, Casual=$casualTaken, Unpaid=$unpaidTaken');
    // Return the calculated values
    return (sick: sickTaken, casual: casualTaken, unpaid: unpaidTaken);
  }

  // Show Apply Leave Modal
  void _showApplyLeaveModal() {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cannot apply: Not authenticated.'),
          backgroundColor: Colors.red));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Pass fetchLeaves directly as the callback
        return ApplyLeaveModal(
            apiService: _leaveApiService,
            authToken: _authToken!,
            onApplied: _fetchLeaves);
      },
    );
  }

  // Show Leave Details Dialog
  void _showLeaveDetailsDialog(LeaveApplication application) {
    showDialog(
      context: context,
      builder: (context) => LeaveDetailsDialog(
        application: application,
        onDelete: () async {
          Navigator.of(context).pop(); // Close dialog *before* starting delete
          await _deleteLeaveApplication(application.id);
        },
      ),
    );
  }

  // Delete Leave Application Method
  Future<void> _deleteLeaveApplication(int leaveId) async {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cannot delete: Not authenticated.'),
          backgroundColor: Colors.red));
      return;
    }
    // Find the leave to check its properties before showing confirmation
    LeaveApplication? leaveToDelete;
    try {
      leaveToDelete =
          _leaveApplications.firstWhere((leave) => leave.id == leaveId);
    } catch (_) {
      print("Leave with ID $leaveId not found in local list.");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not find leave to delete.'),
            backgroundColor: Colors.orange));
      return;
    }

    // --- Check Deletion Eligibility ---
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final leaveEndDate = DateTime(leaveToDelete.endDate.year,
        leaveToDelete.endDate.month, leaveToDelete.endDate.day);
    final bool isPastLeave = leaveEndDate.isBefore(today);
    final bool canDelete = !isPastLeave &&
        (leaveToDelete.status == 'PENDING' ||
            (leaveToDelete.status == 'APPROVED' &&
                leaveToDelete.deductedAs.toUpperCase() == 'UNPAID'));

    if (!canDelete) {
      String reason = isPastLeave
          ? "Cannot delete past leave applications."
          : "Cannot delete approved leaves deducted from Sick/Casual quota.";
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(reason), backgroundColor: Colors.orange));
      return;
    }
    // --- End Check ---

    bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Confirm Deletion'),
              content: const Text(
                  'Are you sure you want to delete this leave application? This action cannot be undone.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red))),
              ],
            ));
    if (confirm != true) return;

    // Use mounted check before setState
    if (mounted) setState(() => _isDeleting = true);

    try {
      await _leaveApiService.deleteLeave(leaveId, _authToken!);
      // Re-fetch the list AFTER successful deletion to update UI & balance
      await _fetchLeaves(); // _fetchLeaves will reset _isDeleting flag
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Leave application deleted successfully.'),
            backgroundColor: Colors.green));
    } catch (e) {
      print('Error deleting leave from UI: $e');
      if (mounted) {
        // Error message shown here
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Failed to delete leave: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red));
        // Reset deleting flag even on error
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('HR Portal',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        // Refresh Button
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: (_isLoading || _isDeleting) ? null : _fetchLeaves,
            tooltip: 'Refresh Leave Data',
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchLeaves,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeacherInfoCard(),
                  const SizedBox(height: 24),
                  const Text('Leave Balance Overview',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildLeaveBalance(), // Uses state variables directly
                  const SizedBox(height: 24),
                  const Text('Leave Application Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildLeaveStatusSection(),
                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
            ),
          ),
          if (_isDeleting) // Deleting Overlay
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                  child: Card(
                      elevation: 4,
                      child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Deleting leave...')
                              ])))),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showApplyLeaveModal,
        label: const Text('Apply for Leave'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Section to handle loading/error/list display
  Widget _buildLeaveStatusSection() {
    if (_isLoading && !_isDeleting) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 40),
                    const SizedBox(height: 8),
                    Text('Error: $_errorMessage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _fetchLeaves, child: const Text('Retry'))
                  ])));
    }
    // Use mounted check here for safety, though less critical than in async gaps
    if (mounted && _leaveApplications.isEmpty && !_isLoading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Text('No leave applications submitted yet.',
                  style: TextStyle(color: Colors.grey))));
    }
    return _buildLeaveStatusList();
  }

  Widget _buildTeacherInfoCard() {
    // This widget remains the same
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prof. Ramswaroop Sir',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('ID: 123456', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text('Mathematics Teacher',
                    style: TextStyle(color: Colors.blueAccent[700])),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/profile.png'),
            onBackgroundImageError: null,
            child: Icon(Icons.person,
                size: 30, color: Colors.grey), // Fallback Icon
          ),
        ],
      ),
    );
  }

  // Updated Leave Balance Widget
  Widget _buildLeaveBalance() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
            child: _buildLeaveIndicator(
                'Sick Leave', _sickLeavesTaken, _totalSickLeaves, Colors.red)),
        Flexible(
            child: _buildLeaveIndicator('Casual Leave', _casualLeavesTaken,
                _totalCasualLeaves, Colors.blue)),
        Flexible(
            child: _buildLeaveIndicator('Unpaid Leave', _unpaidLeavesTaken,
                _totalUnpaidLeaves, Colors.purple)),
      ],
    );
  }

  // Updated Leave Indicator Widget
  Widget _buildLeaveIndicator(String label, int value, int total, Color color) {
    // **FIX for Unpaid Loader:** Explicitly set progress value, even if 0
    double progress = total > 0 ? (value / total) : 0.0;
    String availableText = total > 0
        ? 'Available: ${total - value}'
        : ''; // Calculate available if quota exists

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
            height: 80,
            width: 80,
            child: Stack(fit: StackFit.expand, children: [
              CircularProgressIndicator(
                value: progress, // Use calculated progress (0.0 if total is 0)
                strokeWidth: 7,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                  child: Text(
                      total > 0
                          ? '$value/$total'
                          : '$value', // Show fraction or just value
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))),
            ])),
        const SizedBox(height: 8),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        if (total > 0)
          Text(availableText,
              style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        if (total <= 0)
          const SizedBox(height: 14), // Placeholder for consistent layout
      ],
    );
  }

  // Builds the list view for leave applications
  Widget _buildLeaveStatusList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _leaveApplications.length,
      itemBuilder: (context, index) {
        final application = _leaveApplications[index];
        return _buildLeaveStatusCard(application);
      },
    );
  }

  // Builds a single card for the leave application list
  Widget _buildLeaveStatusCard(LeaveApplication application) {
    Color statusColor;
    String statusText = application.displayStatus;
    switch (application.status) {
      case 'APPROVED':
        statusColor = Colors.green;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange; // PENDING
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showLeaveDetailsDialog(application),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          title: Text(application.displayLeaveType,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
              '${application.dateRangeDisplay}\nReason: ${application.reason}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(statusText,
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
} // End _HRSectionScreenState

// --- Apply Leave Modal ---
class ApplyLeaveModal extends StatefulWidget {
  final LeaveApiService apiService;
  final String authToken;
  final VoidCallback onApplied;
  const ApplyLeaveModal(
      {super.key,
      required this.apiService,
      required this.authToken,
      required this.onApplied});
  @override
  State<ApplyLeaveModal> createState() => _ApplyLeaveModalState();
}

class _ApplyLeaveModalState extends State<ApplyLeaveModal> {
  String? _selectedLeaveTypeApiValue;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final now = DateTime.now();
    final initialPickerDate =
        isStartDate ? (_startDate ?? now) : (_endDate ?? _startDate ?? now);
    final firstAllowedDate = isStartDate
        ? DateTime(now.year, now.month, now.day)
        : _startDate ?? DateTime(now.year, now.month, now.day);
    final lastAllowedDate = DateTime(now.year + 1, now.month, now.day);
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialPickerDate.isBefore(firstAllowedDate)
            ? firstAllowedDate
            : initialPickerDate,
        firstDate: firstAllowedDate,
        lastDate: lastAllowedDate);
    if (picked != null) {
      setState(() {
        final formattedDate = DateFormat('MMM dd, yyyy').format(picked);
        if (isStartDate) {
          _startDate = picked;
          _startController.text = formattedDate;
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = null;
            _endController.text = '';
          } else if (_endDate == null) {
            _endDate = _startDate;
            _endController.text = formattedDate;
          }
        } else {
          if (_startDate != null && picked.isBefore(_startDate!)) {
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('End date cannot be before start date.'),
                  backgroundColor: Colors.orange));
            return;
          }
          _endDate = picked;
          _endController.text = formattedDate;
        }
      });
    }
  }

  Future<void> _submitLeaveApplication() async {
    if (_selectedLeaveTypeApiValue == null ||
        _startDate == null ||
        _endDate == null ||
        _reasonController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _errorMessage = 'End date cannot be before start date.');
      return;
    }
    print('--- Submitting Leave ---'); /* ... debug prints ... */
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.apiService.applyLeave(
          leaveType: _selectedLeaveTypeApiValue!,
          reason: _reasonController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          authToken: widget.authToken);
      if (mounted) {
        widget.onApplied();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Leave application submitted successfully!'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Apply for Leave',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context))
              ]),
              const SizedBox(height: 20),
              // --- UPDATED Dropdown Items to include UNPAID ---
              _buildDropdown('Leave Type', 'Select Leave Type', {
                'Sick Leave': 'SICK',
                'Casual Leave': 'CASUAL',
                'Unpaid Leave': 'UNPAID' // Added Unpaid
              }),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _buildDatePicker('From', _startController,
                        () => _selectDate(context, true))),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildDatePicker('To', _endController,
                        () => _selectDate(context, false))),
              ]),
              const SizedBox(height: 16),
              _buildReasonField(),
              if (_errorMessage != null)
                Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center)),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitLeaveApplication,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        disabledBackgroundColor: Colors.grey.shade400),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Apply Leave',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                  )),
            ])),
      ),
    );
  }

  Widget _buildDropdown(String label, String hint, Map<String, String> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1))
            ]),
        child: DropdownButtonFormField<String>(
          value: _selectedLeaveTypeApiValue,
          hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
          items: items.entries
              .map((entry) => DropdownMenuItem<String>(
                  value: entry.value, child: Text(entry.key)))
              .toList(),
          onChanged: (newValue) =>
              setState(() => _selectedLeaveTypeApiValue = newValue),
          decoration: const InputDecoration(border: InputBorder.none),
          isExpanded: true,
        ),
      ),
    ]);
  }

  Widget _buildDatePicker(
      String label, TextEditingController controller, VoidCallback onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
              hintText: 'Select Date',
              filled: true,
              fillColor: Colors.white,
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12))),
    ]);
  }

  Widget _buildReasonField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Reason', style: TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextField(
          controller: _reasonController,
          maxLines: 4,
          decoration: InputDecoration(
              hintText: 'Please provide a reason for your leave',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12))),
    ]);
  }
} // End _ApplyLeaveModalState

// --- UPDATED Leave Details Dialog Widget ---
class LeaveDetailsDialog extends StatelessWidget {
  final LeaveApplication application;
  final VoidCallback onDelete;

  const LeaveDetailsDialog(
      {super.key, required this.application, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (application.status) {
      case 'APPROVED':
        statusColor = Colors.green;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange; // PENDING
    }

    // --- Deletion Logic ---
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final leaveEndDate = DateTime(application.endDate.year,
        application.endDate.month, application.endDate.day);
    final bool isPastLeave = leaveEndDate.isBefore(today);
    final bool canDelete = !isPastLeave &&
        (application.status == 'PENDING' ||
            (application.status == 'APPROVED' &&
                application.deductedAs.toUpperCase() == 'UNPAID'));
    // --- END Deletion Logic ---

    return AlertDialog(
      title: Text(application.displayLeaveType),
      content: SingleChildScrollView(
        child: ListBody(children: <Widget>[
          _buildDetailRow('Status:', application.displayStatus, statusColor),
          const SizedBox(height: 10),
          _buildDetailRow('Dates:', application.dateRangeDisplay),
          const SizedBox(height: 10),
          _buildDetailRow('Reason:', application.reason),
          const SizedBox(height: 10),
          _buildDetailRow(
              'Deducted As:',
              application.deductedAs.isNotEmpty
                  ? application.deductedAs
                  : 'N/A'),
          const SizedBox(height: 10),
          _buildDetailRow('Duration:',
              '${application.endDate.difference(application.startDate).inDays + 1} day(s)'),
        ]),
      ),
      actions: <Widget>[
        TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop()),
        if (canDelete)
          TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: onDelete),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: 90,
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
      const SizedBox(width: 8),
      Expanded(
          child: Text(value,
              style: TextStyle(color: valueColor ?? Colors.black87))),
    ]);
  }
} // End LeaveDetailsDialog
