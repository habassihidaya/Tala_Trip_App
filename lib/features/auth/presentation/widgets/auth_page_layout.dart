import 'package:flutter/material.dart';

class AuthPageLayout extends StatelessWidget {
  static const blue = Color(0xFF4972A1);
  static const navy = Color(0xFF111944);
  static const muted = Color(0xFF58627D);
  static const beige = Color(0xFFD7B9B0);
  static const mauve = Color(0xFFAA8285);

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final bool spacious;

  const AuthPageLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.spacious = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFCAD1DF)),
    );
    final theme = base.copyWith(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: blue,
        brightness: Brightness.light,
      ).copyWith(primary: blue, secondary: mauve, surface: Colors.white),
      scaffoldBackgroundColor: const Color(0xFFFFFEFC),
      textTheme: base.textTheme.apply(bodyColor: navy, displayColor: navy),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: Colors.white,
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        prefixIconColor: navy,
        suffixIconColor: navy,
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(color: muted),
        errorMaxLines: 3,
        helperMaxLines: 3,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFDCE4EE),
          disabledForegroundColor: muted,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: blue,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFDFE3EA)),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 690),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (onBack != null) ...[
                          IconButton(
                            tooltip: 'Back',
                            onPressed: onBack,
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: blue,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ],
                    ),
                    SizedBox(height: spacious ? 32 : 28),
                    Image.asset(
                      'assets/logos/tala_logo.png',
                      width: 200,
                      height: 164,
                      fit: BoxFit.contain,
                      color: const Color.fromARGB(255, 1, 75, 145),
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    SizedBox(height: spacious ? 16 : 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.8,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
