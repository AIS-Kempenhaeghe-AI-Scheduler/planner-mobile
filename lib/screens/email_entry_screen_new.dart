import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_provider.dart';
import 'login_screen_new.dart';

class EmailEntryScreen extends StatefulWidget {
  const EmailEntryScreen({super.key});

  @override
  State<EmailEntryScreen> createState() => _EmailEntryScreenState();
}

class _EmailEntryScreenState extends State<EmailEntryScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveEmailAndNavigate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', _emailController.text.trim());

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NewLoginScreen(
            prefilledEmail: _emailController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to save email. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }

    final emailRegExp =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? ThemeProvider.notionBlack : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1A1A1A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode
                                ? const Color(0xFF2D2D2D)
                                : const Color(0xFFE5E5E5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDarkMode ? 0.3 : 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/logo/Kempenhaeghe_logo.png',
                              width: 160,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'AI Healthcare Scheduling',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.white
                                    : ThemeProvider.notionBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Welcome to your digital workspace',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Form section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1A1A1A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode
                                ? const Color(0xFF2D2D2D)
                                : const Color(0xFFE5E5E5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDarkMode ? 0.2 : 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: ThemeProvider.notionBlue
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.email_outlined,
                                      size: 20,
                                      color: ThemeProvider.notionBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Get started',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode
                                                ? Colors.white
                                                : ThemeProvider.notionBlack,
                                          ),
                                        ),
                                        Text(
                                          'Enter your work email to continue',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDarkMode
                                                ? const Color(0xFF9CA3AF)
                                                : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Email field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !_isLoading,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDarkMode
                                      ? Colors.white
                                      : ThemeProvider.notionBlack,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Work email address',
                                  labelStyle: TextStyle(
                                    color: isDarkMode
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    size: 20,
                                    color: isDarkMode
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280),
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode
                                      ? const Color(0xFF111111)
                                      : const Color(0xFFF8F9FA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDarkMode
                                          ? const Color(0xFF2D2D2D)
                                          : const Color(0xFFE5E5E5),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDarkMode
                                          ? const Color(0xFF2D2D2D)
                                          : const Color(0xFFE5E5E5),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: ThemeProvider.notionBlue,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFEF4444),
                                      width: 1,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFEF4444),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: _validateEmail,
                                onFieldSubmitted: (_) =>
                                    _saveEmailAndNavigate(),
                              ),

                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFEF4444)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Color(0xFFEF4444),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Color(0xFFEF4444),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Continue button
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _saveEmailAndNavigate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ThemeProvider.notionBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    disabledBackgroundColor: ThemeProvider
                                        .notionBlue
                                        .withOpacity(0.5),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'Continue',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Footer text
                              Text(
                                'By continuing, you agree to our Terms of Service and Privacy Policy.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
