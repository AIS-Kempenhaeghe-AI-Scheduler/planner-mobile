import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/theme_provider.dart';

class PinResetDialog extends StatefulWidget {
  const PinResetDialog({super.key});

  @override
  State<PinResetDialog> createState() => _PinResetDialogState();
}

class _PinResetDialogState extends State<PinResetDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPin = true;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _resetPin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPinController.text != _confirmPinController.text) {
      _showMessage('New PIN and confirmation PIN do not match', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.resetPin(
      _currentPinController.text,
      _newPinController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      _showMessage(result['message'], isError: false);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    } else {
      _showMessage(result['message'], isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : ThemeProvider.notionBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  String? _validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter PIN';
    }
    if (value.length != 6) {
      return 'PIN must be 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'PIN must contain only numbers';
    }
    return null;
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? ThemeProvider.notionGray : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: validator,
          style: TextStyle(
            fontSize: 16,
            letterSpacing: 8,
            color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              letterSpacing: 8,
            ),
            filled: true,
            fillColor:
                isDarkMode ? ThemeProvider.notionDarkGray : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
                color: isDarkMode ? ThemeProvider.notionGray : Colors.grey[600],
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF2D2D2D)
                  : const Color(0xFFE5E5E5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode
                            ? const Color(0xFF2D2D2D)
                            : const Color(0xFFE5E5E5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ThemeProvider.notionBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          color: ThemeProvider.notionBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reset PIN',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.white
                                    : ThemeProvider.notionBlack,
                              ),
                            ),
                            Text(
                              'Change your 6-digit PIN',
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
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form fields
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildPinField(
                        controller: _currentPinController,
                        label: 'CURRENT PIN',
                        hint: '••••••',
                        obscureText: _obscureCurrentPin,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureCurrentPin = !_obscureCurrentPin;
                          });
                        },
                        validator: _validatePin,
                      ),

                      const SizedBox(height: 20),

                      _buildPinField(
                        controller: _newPinController,
                        label: 'NEW PIN',
                        hint: '••••••',
                        obscureText: _obscureNewPin,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureNewPin = !_obscureNewPin;
                          });
                        },
                        validator: _validatePin,
                      ),

                      const SizedBox(height: 20),

                      _buildPinField(
                        controller: _confirmPinController,
                        label: 'CONFIRM NEW PIN',
                        hint: '••••••',
                        obscureText: _obscureConfirmPin,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureConfirmPin = !_obscureConfirmPin;
                          });
                        },
                        validator: _validatePin,
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                  color: isDarkMode
                                      ? const Color(0xFF2D2D2D)
                                      : const Color(0xFFE5E5E5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.white
                                      : ThemeProvider.notionBlack,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _resetPin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ThemeProvider.notionBlue,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                disabledBackgroundColor:
                                    ThemeProvider.notionBlue.withOpacity(0.5),
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
                                  : const Text(
                                      'Reset PIN',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Security note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ThemeProvider.notionBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ThemeProvider.notionBlue.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: ThemeProvider.notionBlue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your new PIN will be used for all future logins. Keep it secure!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ThemeProvider.notionBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
