import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/visitor_service.dart';
import 'services/auth_service.dart';
import 'package:intl/intl.dart';
import 'qr_scanner_screen.dart';
import 'services/vip_service.dart';
import 'login_screen.dart';
import 'services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final VisitorService _visitorService = VisitorService();
  final AuthService _authService = AuthService();
  final VipService _vipService = VipService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTab = 'VIPs';

  final List<String> _tabs = [
    'VIPs',
    'Pending',
    'On Hold',
    'Declined',
    'Blacklisted',
    'Approved',
    'All'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabs[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to log out from the VIMS Portal?',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.clearSession();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                Text('Logout', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRegisterVipDialog() async {
    final nameController = TextEditingController();
    final designationController = TextEditingController();
    final orgController = TextEditingController();
    final vehicleController = TextEditingController();
    String? selectedOperatorId;
    String? selectedOperatorName;

    // Fetch operators first
    final List<Map<String, dynamic>> operators =
        await _authService.getOperators();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          contentPadding: const EdgeInsets.all(24),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clean Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[50], // Light gold background
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber[100]!),
                        ),
                        child: const Icon(Icons.stars,
                            color: Color(0xFFFFB300), size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Register VIP Guest',
                                style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text('Auto-approved with unrestricted access',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Form Fields
                  _buildPremiumField(
                    controller: nameController,
                    label: 'VIP Name',
                    hint: 'Enter full name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumField(
                    controller: designationController,
                    label: 'Designation',
                    hint: 'e.g. Managing Director',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumField(
                    controller: orgController,
                    label: 'Organization / Department',
                    hint: 'e.g. TNB Energy',
                    icon: Icons.business_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumField(
                    controller: vehicleController,
                    label: 'Vehicle Number (Optional)',
                    hint: 'e.g. ABC 1234',
                    icon: Icons.directions_car_outlined,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  // Fixed Overflow Dropdown
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "Assign Operator",
                      labelStyle: GoogleFonts.inter(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      prefixIcon: const Icon(Icons.security_outlined,
                          color: Color(0xFF2C3E50), size: 20),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF2C3E50), width: 1.5),
                      ),
                    ),
                    value: selectedOperatorId,
                    hint: Text("Select Security Personnel",
                        style: GoogleFonts.inter(
                            fontSize: 14, color: Colors.grey)),
                    items: operators.map((op) {
                      return DropdownMenuItem<String>(
                        value: op['username'],
                        child: Text(op['username'] ?? 'Unknown',
                            style: GoogleFonts.inter(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedOperatorId = val;
                        selectedOperatorName = operators.firstWhere((element) =>
                            element['username'] == val)['username'];
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  // Footer Actions
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Cancel',
                              style: GoogleFonts.inter(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2C3E50), Color(0xFF4C5E70)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2C3E50).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              if (nameController.text.isEmpty ||
                                  selectedOperatorId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please fill Name and Assign Operator'),
                                      backgroundColor: Colors.orange),
                                );
                                return;
                              }

                              // Show loading
                              showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                      child: CircularProgressIndicator()));

                              try {
                                final ticketId =
                                    await _vipService.createVipTicket(
                                  vipName: nameController.text,
                                  designation: designationController.text,
                                  organization: orgController.text,
                                  vehicleNumber:
                                      vehicleController.text.toUpperCase(),
                                  escortOperatorId: selectedOperatorId!,
                                  escortName:
                                      selectedOperatorName ?? 'Operator',
                                );

                                // Send Notification to assigned operator
                                final operatorData = await _authService
                                    .getUserByUsername(selectedOperatorId!);
                                if (operatorData != null &&
                                    operatorData['fcmToken'] != null) {
                                  await NotificationService.sendNotification(
                                    fcmToken: operatorData['fcmToken'],
                                    title: 'New VIP Assigned',
                                    body:
                                        'You have been assigned to escort VIP: ${nameController.text}. Tap to view QR.',
                                    data: {
                                      'type': 'vip_assignment',
                                      'ticketId': ticketId,
                                      'vipName': nameController.text,
                                    },
                                  );
                                }

                                if (mounted) {
                                  Navigator.pop(context); // Close loading
                                  Navigator.pop(context); // Close dialog
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'VIP Ticket Created & Operator Alerted'),
                                        backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  Navigator.pop(context); // Close loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Generate VIP',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
            color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF2C3E50), size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C3E50), width: 1.5),
        ),
      ),
    );
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return '-';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        dt = DateTime.parse(timestamp);
      } catch (e) {
        return timestamp;
      }
    } else {
      return '-';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(dt.year, dt.month, dt.day);

    if (dateToCheck == today) {
      return 'Today, ${DateFormat('h:mm a').format(dt)}';
    } else {
      return DateFormat('MMM d, yyyy h:mm a').format(dt);
    }
  }

  Future<void> _handleQRScan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null && result is String) {
      final visitorDoc = await _visitorService.getVisitorById(result);
      if (visitorDoc != null) {
        if (!mounted) return;

        final data = visitorDoc.data() as Map<String, dynamic>;
        final String? vId = data['visitorId'];

        // CHECK GLOBAL PROFILE BLOCK STATUS
        bool isGloballyBlocked = false;
        String? globalBlockReason;

        if (vId != null && vId.isNotEmpty) {
          final profileDoc = await _visitorService.getVisitorProfile(vId);
          if (profileDoc != null) {
            final profileData = profileDoc.data() as Map<String, dynamic>;
            if (profileData['isBlocked'] == true) {
              isGloballyBlocked = true;
              globalBlockReason = profileData['blockReason'];
            }
          }
        }

        final status = (data['status'] ?? '').toString().toLowerCase();
        final isPassBlocked = status.contains('black') ||
            status.contains('block') ||
            status == 'declined';

        if (isGloballyBlocked || isPassBlocked) {
          final String displayReason =
              globalBlockReason ?? data['blockReason'] ?? 'No reason provided';
          // Show ALERT for blacklisted visitor
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 30),
                  const SizedBox(width: 10),
                  Text('ACCESS DENIED',
                      style: GoogleFonts.inter(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Visitor: ${data['visitorName'] ?? 'Unknown'}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                      'CRITICAL: This visitor is on the GLOBAL BLACKLIST.'),
                  const SizedBox(height: 8),
                  const Text(
                      'Security personnel should be alerted immediately.',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Reason:',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey[700])),
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Text(displayReason,
                        style: GoogleFonts.inter(color: Colors.red[900])),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Dismiss',
                      style: GoogleFonts.inter(color: Colors.grey[600])),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showVisitorDetails(visitorDoc.id, data);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text('View Details',
                      style: GoogleFonts.inter(color: Colors.white)),
                ),
              ],
            ),
          );
        } else {
          _showVisitorDetails(visitorDoc.id, data);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Visitor with ID $result not found'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _buildHeader(isMobile),
          Expanded(
            child: isMobile ? _buildMobileView() : _buildWebView(),
          ),
        ],
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: _handleQRScan,
              backgroundColor: const Color(0xFF6200EE),
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: Text('Scan QR',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2979FF), Color(0xFF9C27B0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 20,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.security, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VIMS Operator Portal',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: isMobile ? 18 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Visitor Integrated Management System',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Logged in as',
                    style:
                        GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'Security Operator',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                backgroundColor: Colors.amber,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.stars, color: Colors.white),
              onPressed: _showRegisterVipDialog,
              tooltip: 'Register VIP Guest',
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _showLogoutDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by name, IC, status, mobile...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildWebActionButton(Icons.qr_code_scanner, 'Scan QR',
                  const Color(0xFF6200EE), Colors.white,
                  isGradient: true, onTap: _handleQRScan),
              const SizedBox(width: 16),
              _buildWebActionButton(Icons.stars, 'Register VIP',
                  const Color(0xFFFFD700), Colors.black,
                  onTap: _showRegisterVipDialog),
            ],
          ),
          const SizedBox(height: 24),
          _buildTabBar(),
          const SizedBox(height: 24),
          _buildDataTable(),
          const SizedBox(height: 32),
          _buildAutomationRules(),
        ],
      ),
    );
  }

  Widget _buildWebActionButton(
      IconData icon, String label, Color bgColor, Color textColor,
      {bool isGradient = false, VoidCallback? onTap}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isGradient ? null : bgColor,
        gradient: isGradient
            ? const LinearGradient(
                colors: [Color(0xFF2979FF), Color(0xFF9C27B0)])
            : null,
        borderRadius: BorderRadius.circular(12),
        border: !isGradient ? Border.all(color: Colors.grey[200]!) : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onTap ?? () {},
        icon: Icon(icon, color: textColor, size: 20),
        label: Text(label,
            style: GoogleFonts.inter(
                color: textColor, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: _selectedTab == 'VIPs' ? Colors.black : Colors.white,
        unselectedLabelColor: Colors.grey[600],
        padding: const EdgeInsets.symmetric(vertical: 8),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _selectedTab == 'VIPs'
              ? const Color(0xFFFFD700)
              : _selectedTab == 'Blacklisted'
                  ? Colors.red
                  : const Color(0xFF448AFF),
        ),
        tabs: _tabs
            .map((tab) => Tab(
                child: Text(tab,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold))))
            .toList(),
      ),
    );
  }

  Widget _buildDataTable() {
    final bool isBlacklisted = _selectedTab == 'Blacklisted';
    final bool isVips = _selectedTab == 'VIPs';
    final bool isAll = _selectedTab == 'All';

    final stream = isVips
        ? _vipService.getActiveVipTickets()
        : _visitorService.getVisitorPasses();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data?.docs ?? [];

        // 1. Filter by Selected Tab (Status)
        if (isAll) {
          // No filtering for All tab
        } else if (isBlacklisted) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString().toLowerCase();
            return data['isBlocked'] == true ||
                status.contains('black') ||
                status.contains('block') ||
                status == 'declined';
          }).toList();
        } else if (!isVips) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString().toLowerCase();

            if (_selectedTab == 'Blacklisted') {
              return status.contains('black') ||
                  status.contains('block') ||
                  status == 'declined';
            }
            return status == _selectedTab.toLowerCase() ||
                (data['status'] ?? '') == _selectedTab;
          }).toList();
        }

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['visitorName'] ?? '').toString().toLowerCase();
            final id = (data['idNumber'] ?? '').toString().toLowerCase();
            final mobile = (data['mobile'] ?? '').toString().toLowerCase();
            final vId = (data['visitorId'] ?? '').toString().toLowerCase();

            String status = '';
            if (isVips) {
              status = 'approved';
            } else {
              // For normal passes, use the status field
              status = (data['status'] ?? '').toString().toLowerCase();
              // Normalize blacklisted status for search
              if (data['isBlocked'] == true) status = 'blacklisted';
            }

            final vipFields = isVips
                ? (data['vipName'] ?? '') +
                    (data['designation'] ?? '') +
                    (data['organization'] ?? '') +
                    (data['escortName'] ?? '')
                : '';

            return name.contains(query) ||
                id.contains(query) ||
                mobile.contains(query) ||
                status.contains(query) ||
                vId.contains(query) ||
                vipFields.toLowerCase().contains(query);
          }).toList();
        }

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FD)),
              columns: [
                _buildDataColumn(isVips ? 'VIP Guest' : 'Name & IC'),
                _buildDataColumn(isVips ? 'Organization' : 'Contact'),
                if (!isVips) _buildDataColumn('Vehicle'),
                if (!isVips) _buildDataColumn('Category'),
                if (isVips) _buildDataColumn('Escorted By'),
                _buildDataColumn('Status'),
                _buildDataColumn('Actions'),
              ],
              rows: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DataRow(cells: [
                  DataCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          isVips
                              ? (data['vipName'] ?? 'No Name')
                              : (data['visitorName'] ?? 'No Name'),
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      if (data['idNumber'] != null || isVips)
                        Text(
                            isVips
                                ? (data['designation'] ?? '')
                                : (data['idNumber'] ?? ''),
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.grey)),
                    ],
                  )),
                  DataCell(Text(
                      isVips
                          ? (data['organization'] ?? '')
                          : (data['mobile'] ?? ''),
                      style: GoogleFonts.inter())),
                  if (!isVips)
                    DataCell(Text(data['vehicleNumber'] ?? '-',
                        style: GoogleFonts.inter())),
                  if (!isVips) DataCell(_buildCategoryBadge(data)),
                  if (isVips)
                    DataCell(Text(data['escortName'] ?? '-',
                        style: GoogleFonts.inter())),
                  DataCell(isVips
                      ? _buildStatusChip('Approved')
                      : _buildStatusChip(data['status'] ??
                          (data['isBlocked'] == true
                              ? 'Blacklisted'
                              : 'Pending'))),
                  DataCell(Row(
                    children: [
                      if (isVips)
                        InkWell(
                          onTap: () => _showVipQrCode(data),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber[200]!),
                            ),
                            child: const Icon(Icons.qr_code_2,
                                color: Color(0xFFFFB300), size: 18),
                          ),
                        ),
                      InkWell(
                        onTap: () => _showVisitorDetails(doc.id, data),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.remove_red_eye_outlined,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text('View',
                                  style: GoogleFonts.inter(
                                      color: Colors.blue, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryBadge(Map<String, dynamic> data) {
    // Priority 1: Check if there's an explicit 'category' field
    if (data.containsKey('category') &&
        data['category'] != null &&
        data['category'].toString().isNotEmpty) {
      String cat = data['category'].toString();
      Color color = Colors.blue;
      if (cat.toLowerCase().contains('white')) color = Colors.green;
      if (cat.toLowerCase().contains('yellow')) color = Colors.amber;
      if (cat.toLowerCase().contains('orange')) color = Colors.orange;
      if (cat.toLowerCase().contains('red')) color = Colors.red;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Text(cat,
            style: GoogleFonts.inter(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }

    // Priority 2: Derive from status
    String status = (data['status'] ?? '').toString().toLowerCase();
    Color color = Colors.grey;
    String label = 'White';

    if (status == 'approved') {
      color = Colors.green;
      label = 'White';
    } else if (status == 'pending') {
      color = Colors.orange;
      label = 'Orange';
    } else if (status.contains('black') ||
        status.contains('block') ||
        status == 'declined') {
      color = Colors.red;
      label = 'Red';
    } else if (status == 'on hold') {
      color = Colors.amber;
      label = 'Yellow';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.block, size: 60, color: Colors.red[300]),
            ),
            const SizedBox(height: 24),
            Text(
              'No $_selectedTab Visitors',
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 8),
            Text(
              'There are currently no visitors in this section.',
              style: GoogleFonts.inter(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showVisitorDetails(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FD),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Visitor Pass',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500)),
                        Text(data['visitorId'] ?? 'N/A',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2C3E50))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusChip(data['status'] ??
                          (data['isBlocked'] != null
                              ? (data['isBlocked'] == true
                                  ? 'Blacklisted'
                                  : 'Approved')
                              : 'Pending')),
                      if (data
                          .containsKey('purpose')) // Only show for visit passes
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: InkWell(
                            onTap: () {
                              if (data['visitorId'] != null) {
                                Navigator.pop(context); // Close visit pass
                                _showMasterProfile(data['visitorId']);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.deepPurple.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.account_circle_outlined,
                                      size: 14, color: Colors.deepPurple),
                                  const SizedBox(width: 4),
                                  Text('View Profile',
                                      style: GoogleFonts.inter(
                                          color: Colors.deepPurple,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    if (data.containsKey('vipName'))
                      _buildVipDetailCard(data)
                    else if (data.containsKey('purpose'))
                      _buildPremiumDetailCard(data)
                    else
                      _buildProfileDetailCard(data),
                    const SizedBox(height: 24),
                    _buildStatusUpdateSection(docId, data),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVipDetailCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDetailRowItem(Icons.person, 'VIP Name', data['vipName']),
          _buildDetailSeparator(),
          _buildDetailRowItem(
              Icons.badge_outlined, 'Designation', data['designation']),
          _buildDetailSeparator(),
          _buildDetailRowItem(
              Icons.business_outlined, 'Organization', data['organization']),
          _buildDetailSeparator(),
          _buildDetailRowItem(Icons.assignment_ind_outlined, 'Escort Operator',
              data['escortName']),
          _buildDetailSeparator(),
          _buildDetailRowItem(Icons.calendar_today_outlined, 'Created On',
              _formatDateTime(data['createdAt'])),
          _buildDetailSeparator(),
          _buildDetailRowItem(Icons.location_on_outlined, 'Last Checkpoint',
              data['lastCheckpoint'] ?? 'N/A'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showVipQrCode(data),
            icon: const Icon(Icons.qr_code, color: Colors.black),
            label: Text('Display VIP Access QR',
                style: GoogleFonts.inter(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showVipQrCode(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: Color(0xFFFFD700), size: 40),
            const SizedBox(height: 8),
            Text('VIP Access QR',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            Text(data['vipName'] ?? 'Guest',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: QrImageView(
                  data: data['ticketId'] ?? 'INVALID',
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              Text('Scan at any checkpoint for instant log & bypass.',
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  void _showMasterProfile(String visitorId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final profileDoc = await _visitorService.getVisitorProfile(visitorId);

    if (mounted) Navigator.pop(context); // Close loading

    if (profileDoc != null) {
      if (mounted)
        _showVisitorDetails(
            profileDoc.id, profileDoc.data() as Map<String, dynamic>);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile for ID $visitorId not found')),
        );
      }
    }
  }

  Widget _buildProfileDetailCard(Map<String, dynamic> data) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildDetailRowItem(Icons.person_outline, 'Full Name',
                  data['name'] ?? data['visitorName']),
              _buildDetailSeparator(),
              _buildDetailRowItem(
                  Icons.badge_outlined, 'ID Number', data['idNumber']),
              _buildDetailSeparator(),
              _buildDetailRowItem(Icons.description_outlined, 'Document Type',
                  data['documentType']),
              _buildDetailSeparator(),
              _buildDetailRowItem(Icons.phone_android_outlined, 'Mobile Number',
                  data['mobile']),
              _buildDetailSeparator(),
              _buildDetailRowItem(
                  Icons.email_outlined, 'Email Address', data['email']),
              _buildDetailSeparator(),
              _buildDetailRowItem(
                  Icons.business_outlined, 'Company', data['company'] ?? 'N/A'),
              _buildDetailSeparator(),
              _buildDetailRowItem(
                  Icons.category_outlined, 'Visitor Type', data['visitorType']),
              _buildDetailSeparator(),
              _buildDetailRowItem(
                  Icons.info_outline, 'Registration Status', data['status']),
              _buildDetailSeparator(),
              _buildDetailRowItem(
                  Icons.lock_outline, 'Login Password', data['password']),
              _buildDetailSeparator(),
              _buildDetailRowItem(
                  Icons.notifications_active_outlined,
                  'FCM Token',
                  data['fcmToken'] != null
                      ? '${data['fcmToken'].toString().substring(0, 15)}...'
                      : 'N/A'),
              _buildDetailSeparator(),
              _buildDetailRowItem(Icons.directions_car_filled_outlined,
                  'Vehicle', data['vehicleNumber'] ?? 'N/A'),
              _buildDetailSeparator(),
              _buildDetailRowItem(Icons.calendar_today_outlined,
                  'Registered On', _formatDateTime(data['createdAt'])),
              if (data['isBlocked'] == true) ...[
                _buildDetailSeparator(),
                _buildDetailRowItem(
                    Icons.block_flipped, 'Block Reason', data['blockReason']),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Image Section
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verification Media',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selfie Photo',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildNetworkImage(data['selfieUrl'],
                              height: 150),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID Document Scan',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildNetworkImage(data['idImageUrl'],
                              height: 150, isIdDoc: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkImage(String? url,
      {required double height, bool isIdDoc = false}) {
    if (url == null || url.isEmpty) {
      return Container(
          height: height,
          width: double.infinity,
          color: Colors.grey[100],
          child:
              Icon(isIdDoc ? Icons.badge : Icons.person, color: Colors.grey));
    }

    print('DEBUG IMAGE: Loading image from $url');

    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: height,
          width: double.infinity,
          color: Colors.grey[50],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('DEBUG IMAGE ERROR: Failed to load $url - $error');
        return Container(
          height: height,
          width: double.infinity,
          color: Colors.red[50],
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined,
                  color: Colors.red[300], size: 24),
              const SizedBox(height: 4),
              Text(
                'Image Load Failed',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.red[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'Likely a CORS issue on Web',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.red[400], fontSize: 8),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Fixing Web Images'),
                      content: const Text(
                          'If you are on Web, run this command in your terminal to fix images:\n\n'
                          'gsutil cors set firebase_cors_config.json gs://vibe-a-thon-bugslayer.firebasestorage.app'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                child: const Text('How to Fix',
                    style: TextStyle(
                        fontSize: 10, decoration: TextDecoration.underline)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumDetailCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDetailRowItem(
              Icons.person_outline, 'Full Name', data['visitorName']),
          _buildDetailSeparator(),
          _buildDetailRowItem(
              Icons.badge_outlined, 'ID Number', data['idNumber']),
          _buildDetailSeparator(),
          _buildDetailRowItem(
              Icons.phone_android_outlined, 'Mobile Number', data['mobile']),
          _buildDetailSeparator(),
          _buildDetailRowItem(Icons.directions_car_filled_outlined,
              'Vehicle Number', data['vehicleNumber']),
          _buildDetailSeparator(),
          _buildDetailRowItem(
              Icons.business_center_outlined, 'Purpose', data['purpose']),
          _buildDetailSeparator(),
          _buildDetailRowItem(
              Icons.person_pin_outlined, 'Host Person', data['hostName']),
          _buildDetailSeparator(),
          _buildDetailRowItem(Icons.location_on_outlined, 'Meeting Level',
              data['meetingLevel']),
          _buildDetailSeparator(),
          _buildDetailRowItem(Icons.calendar_today_outlined, 'Created Date',
              _formatDateTime(data['createdAt'])),
          _buildDetailSeparator(),
          _buildDetailRowItem(Icons.access_time, 'Visit Time',
              '${_formatDateTime(data['visitStart'])} - ${_formatDateTime(data['visitEnd'])}'),
          if (data['blockReason'] != null) ...[
            _buildDetailSeparator(),
            _buildDetailRowItem(
                Icons.block_flipped, 'Block Reason', data['blockReason']),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRowItem(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: const Color(0xFF448AFF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500)),
                Text(value?.toString() ?? '-',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSeparator() =>
      Divider(height: 24, color: Colors.grey[100]);

  Widget _buildStatusUpdateSection(String docId, Map<String, dynamic> data) {
    final bool isVip = data.containsKey('vipName');
    final bool isProfile = !isVip && !data.containsKey('purpose');
    final String? currentStatus = isVip
        ? 'AUTO_APPROVED'
        : (isProfile
            ? (data['isBlocked'] == true ? 'Blacklisted' : 'Approved')
            : data['status']);

    if (isVip) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.stars, color: Color(0xFFFFD700)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'VIP Ticket: Auto-approved with unrestricted access to all TNB locations.',
                style: GoogleFonts.inter(
                    color: const Color(0xFF856404),
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    if (isProfile) {
      final bool isBlocked = data['isBlocked'] == true;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isBlocked ? 'Profile Actions' : 'Security Actions',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50))),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              String? blockReason;

              if (!isBlocked) {
                // PROMPT FOR REASON
                final TextEditingController reasonController =
                    TextEditingController();
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Text('Block Profile',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                            'Provide a reason for blocking this profile globally.'),
                        const SizedBox(height: 16),
                        TextField(
                          controller: reasonController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Enter reason here...',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel',
                            style: GoogleFonts.inter(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (reasonController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter a reason')),
                            );
                            return;
                          }
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: Text('Block Profile',
                            style: GoogleFonts.inter(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;
                blockReason = reasonController.text.trim();
              }

              if (!mounted) return;

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final String? vId = data['visitorId'] ?? docId;
                print(
                    'DEBUG UI: Attempting to update profile status for $vId (isProfile: $isProfile)');
                if (vId != null) {
                  await _visitorService.updateProfileStatus(vId, !isBlocked,
                      blockReason: blockReason);
                } else {
                  print('DEBUG UI ERROR: No ID found to update profile');
                }
              } finally {
                if (mounted) Navigator.pop(context); // Close loading
                if (mounted) Navigator.pop(context); // Close sheet
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isBlocked ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isBlocked ? Colors.green[100]! : Colors.red[100]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isBlocked ? Icons.check_circle_outline : Icons.block,
                      color: isBlocked ? Colors.green : Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    isBlocked ? 'UNBLOCK PROFILE' : 'ADD TO BLOCK LIST',
                    style: GoogleFonts.inter(
                        color: isBlocked ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Update Status',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50))),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children:
              _tabs.where((t) => t != 'All' && t != 'Profiles').map((status) {
            bool isSelected = currentStatus == status;
            Color color = _getStatusColor(status);
            return InkWell(
              onTap: () async {
                String? blockReason;

                // If status is Blacklisted, ask for reason
                if (status == 'Blacklisted') {
                  final TextEditingController reasonController =
                      TextEditingController();
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: Text('Reason for Blocking',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                              'Please provide a reason for adding this visitor to the blacklist.'),
                          const SizedBox(height: 16),
                          TextField(
                            controller: reasonController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Enter reason here...',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel',
                              style: GoogleFonts.inter(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (reasonController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please enter a reason')),
                              );
                              return;
                            }
                            Navigator.pop(context, true);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: Text('Block Visitor',
                              style: GoogleFonts.inter(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;
                  blockReason = reasonController.text.trim();
                }

                if (!mounted) return;

                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    content: Row(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(width: 20),
                        Text('Updating Status...', style: GoogleFonts.inter()),
                      ],
                    ),
                  ),
                );

                try {
                  await _visitorService.updateVisitorStatus(docId, status, data,
                      blockReason: blockReason);
                } finally {
                  // Close loading dialog
                  if (mounted) Navigator.pop(context);
                  // Close bottom sheet
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: isSelected ? color : Colors.grey[200]!),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    status,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'blacklisted':
        return Colors.red[900]!;
      case 'on hold':
        return Colors.orange;
      default:
        return const Color(0xFF448AFF);
    }
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
        label: Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, color: Colors.grey[700])));
  }

  Widget _buildStatusChip(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: GoogleFonts.inter(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildAutomationRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Automation Rules',
            style:
                GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Builder(
          builder: (context) {
            final double screenWidth = MediaQuery.of(context).size.width;
            // Account for horizontal padding (32 * 2 = 64)
            final double availableWidth = screenWidth - 64;
            final double cardWidth =
                (availableWidth - (16 * 3)) / (availableWidth > 1200 ? 4 : 2);

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildRuleCard('White Visitor', 'Auto Approve - Trusted',
                    Colors.green, cardWidth),
                _buildRuleCard('Yellow Visitor', 'Auto Decline - Low priority',
                    Colors.amber, cardWidth),
                _buildRuleCard(
                    'Orange Visitor',
                    'Manual Review - Requires approval',
                    Colors.orange,
                    cardWidth),
                _buildRuleCard('Red Visitor', 'Auto Decline - Restricted',
                    Colors.red, cardWidth),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRuleCard(String title, String desc, Color color, double width) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color, radius: 6),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, color: Colors.black87),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(desc,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // --- MOBILE VIEW ---

  Widget _buildMobileView() {
    final bool isBlacklisted = _selectedTab == 'Blacklisted';
    final bool isVips = _selectedTab == 'VIPs';
    final bool isAll = _selectedTab == 'All';

    final stream = isVips
        ? _vipService.getActiveVipTickets()
        : _visitorService.getVisitorPasses();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: isVips
                  ? 'Search VIPs...'
                  : isBlacklisted
                      ? 'Search blacklist...'
                      : 'Search visitors...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        _buildTabBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var docs = snapshot.data?.docs ?? [];

              // 1. Filter by Selected Tab (Status)
              if (isAll) {
                // No filtering
              } else if (isBlacklisted) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isBlocked'] == true;
                }).toList();
              } else if (!isVips) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status =
                      (data['status'] ?? '').toString().toLowerCase();

                  if (_selectedTab == 'Blacklisted') {
                    return status.contains('black') ||
                        status.contains('block') ||
                        status == 'declined';
                  }
                  return status == _selectedTab.toLowerCase() ||
                      (data['status'] ?? '') == _selectedTab;
                }).toList();
              }

              // 2. Client-side search
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = isVips
                      ? (data['vipName'] ?? '').toString().toLowerCase()
                      : (data['visitorName'] ?? '').toString().toLowerCase();
                  final id = isVips
                      ? (data['designation'] ?? '').toString().toLowerCase()
                      : (data['idNumber'] ?? '').toString().toLowerCase();
                  final mobile = isVips
                      ? (data['organization'] ?? '').toString().toLowerCase()
                      : (data['mobile'] ?? '').toString().toLowerCase();

                  return name.contains(query) ||
                      id.contains(query) ||
                      mobile.contains(query);
                }).toList();
              }

              if (docs.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildMobileVisitorCard(docs[index].id, data,
                      isProfile: false, isVip: isVips);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileVisitorCard(String docId, Map<String, dynamic> data,
      {bool isProfile = false, bool isVip = false}) {
    return InkWell(
      onTap: () =>
          isVip ? _showVipQrCode(data) : _showVisitorDetails(docId, data),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
            ]),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isVip
                        ? const Color(0xFFFFF9C4)
                        : const Color(0xFFE8F0FF),
                    child: Icon(
                      isVip ? Icons.stars : Icons.person,
                      color: isVip ? const Color(0xFFFFB300) : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            isVip
                                ? (data['vipName'] ?? 'No Name')
                                : (data['visitorName'] ?? 'No Name'),
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                            isVip
                                ? (data['designation'] ?? '')
                                : (data['idNumber'] ?? ''),
                            style: GoogleFonts.inter(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isVip)
                    InkWell(
                      onTap: () => _showVipQrCode(data),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.qr_code_2,
                            color: Color(0xFFFFB300)),
                      ),
                    )
                  else
                    _buildStatusChip(isProfile
                        ? (data['isBlocked'] == true
                            ? 'Blacklisted'
                            : 'Approved')
                        : (data['status'] ?? 'Pending')),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMobileInfoItem(
                    isVip ? Icons.business : Icons.phone_outlined,
                    isVip
                        ? (data['organization'] ?? '-')
                        : (data['mobile'] ?? '-'),
                    flex: 2,
                  ),
                  const SizedBox(width: 8),
                  if (!isProfile)
                    _buildMobileInfoItem(
                      Icons.directions_car_outlined,
                      data['vehicleNumber'] ?? '-',
                      flex: 1,
                    ),
                  if (isVip) ...[
                    const SizedBox(width: 8),
                    _buildMobileInfoItem(
                      Icons.person_pin,
                      data['escortName'] ?? '-',
                      flex: 1,
                    ),
                  ],
                  if (isProfile && data['isBlocked'] == true) ...[
                    const SizedBox(width: 8),
                    Text('Blacklisted',
                        style: GoogleFonts.inter(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      _formatDateTime(
                          isProfile ? data['blockedAt'] : data['createdAt']),
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold)),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileInfoItem(IconData icon, String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style:
                    GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }
}
