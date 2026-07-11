import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;

Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  required bool isLoading,
}) {
  final plugin = GoogleSignInPlatform.instance as web.GoogleSignInPlugin;
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: plugin.renderButton(
      configuration: web.GSIButtonConfiguration(
        type: web.GSIButtonType.standard,
        theme: web.GSIButtonTheme.outline,
        size: web.GSIButtonSize.large,
        shape: web.GSIButtonShape.rectangular,
      ),
    ),
  );
}
