import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/theme_provider.dart';
import 'login_screen.dart';
import 'preference_screen.dart';
import 'calendar/schedule_home_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+31 6 12345678');
  final _roleController = TextEditingController();
  final _bioController = TextEditingController(
    text:
        'Experienced care coordinator with a focus on patient-centered scheduling and care management.',
  );
  final _usernameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load user data into form
    _loadUserData();
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _roleController.text = user.role;
      _usernameController.text = user.username;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _bioController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Widget _buildProfileHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: isDarkMode
            ? ThemeProvider.notionDarkGray
            : ThemeProvider.notionFaintBlue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: ThemeProvider.notionBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name.substring(0, 1).toUpperCase()
                        : "U",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: ThemeProvider.notionBlue,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: ThemeProvider.notionBlue,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile photo upload coming soon'),
                      ),
                    );
                  },
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.role ?? 'User',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? ThemeProvider.notionGray : Colors.grey[700],
            ),
          ),
          if (user?.email != null) ...[
            const SizedBox(height: 4),
            Text(
              user!.email,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? ThemeProvider.notionGray : Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotionTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool autofocus = false,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? ThemeProvider.notionGray : Colors.grey[700],
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          autofocus: autofocus,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: maxLines > 1 ? 14 : 15,
            color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            filled: true,
            fillColor:
                isDarkMode ? ThemeProvider.notionDarkGray : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotionCard({
    required String title,
    required List<Widget> children,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: isDarkMode ? ThemeProvider.notionDarkGray : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF404040)
                    : ThemeProvider.notionLightGray,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDarkMode
                    ? ThemeProvider.notionGray
                    : ThemeProvider.notionBlack,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color:
                          isDarkMode ? Colors.white : ThemeProvider.notionBlack,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode
                          ? ThemeProvider.notionGray
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDarkMode ? ThemeProvider.notionGray : Colors.grey[700],
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      // Simulate saving profile
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            backgroundColor: ThemeProvider.notionBlue,
          ),
        );
      });
    }
  }

  void _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();

    if (!mounted) return;

    // Navigate back to login screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context);

    // Redirect to login if not authenticated
    if (!authService.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          _isSaving
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ThemeProvider.notionBlue,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveProfile,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ThemeProvider.notionBlue,
                    ),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // Account Information
            _buildNotionCard(
              title: 'Account Information',
              children: [
                _buildNotionTextField(
                  controller: _usernameController,
                  label: 'USERNAME',
                  hint: 'Your username',
                  readOnly: true, // Username can't be changed
                ),
              ],
            ),

            // Personal Information
            _buildNotionCard(
              title: 'Personal Information',
              children: [
                _buildNotionTextField(
                  controller: _nameController,
                  label: 'FULL NAME',
                  hint: 'Enter your full name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildNotionTextField(
                  controller: _emailController,
                  label: 'EMAIL',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildNotionTextField(
                  controller: _phoneController,
                  label: 'PHONE',
                  hint: 'Enter your phone number',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),

            // Work Information
            _buildNotionCard(
              title: 'Work Information',
              children: [
                _buildNotionTextField(
                  controller: _roleController,
                  label: 'JOB TITLE',
                  hint: 'Enter your job title',
                ),
                const SizedBox(height: 16),
                _buildNotionTextField(
                  controller: _bioController,
                  label: 'BIO',
                  hint: 'Tell us about yourself',
                  maxLines: 4,
                ),
              ],
            ),

            // Preferences
            _buildNotionCard(
              title: 'Preferences',
              children: [
                _buildPreferenceTile(
                  title: 'Schedule Preferences',
                  subtitle: 'Set your preferences for AI scheduling',
                  icon: Icons.event_note,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PreferenceScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildPreferenceTile(
                  title: 'Notification Settings',
                  subtitle: 'Manage how you receive notifications',
                  icon: Icons.notifications_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification settings coming soon'),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildPreferenceTile(
                  title: 'Appearance',
                  subtitle: 'Dark mode and theme settings',
                  icon: Icons.palette_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Appearance settings coming soon'),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildPreferenceTile(
                  title: 'Language',
                  subtitle: 'Change your language preferences',
                  icon: Icons.language_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Language settings coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Security
            _buildNotionCard(
              title: 'Security',
              children: [
                _buildPreferenceTile(
                  title: 'Change Pincode',
                  subtitle: 'Update your pincode',
                  icon: Icons.lock_outline,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pincode change coming soon'),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildPreferenceTile(
                  title: 'Two-Factor Authentication',
                  subtitle: 'Add an extra layer of security',
                  icon: Icons.security_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('2FA coming soon')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Logout and Delete buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor:
                          isDarkMode ? Colors.white : ThemeProvider.notionBlack,
                      side: BorderSide(
                        color: isDarkMode
                            ? const Color(0xFF404040)
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account deletion coming soon'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
