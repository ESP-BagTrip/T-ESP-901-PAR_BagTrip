import 'package:bagtrip/components/snack_bar_scope.dart';
import 'package:flutter/material.dart';

class AppSnackBar {
  static void showError(BuildContext context, {required String message}) =>
      SnackBarScope.of(
        context,
      ).show(context, message: message, type: SnackBarType.error);

  static void showSuccess(BuildContext context, {required String message}) =>
      SnackBarScope.of(
        context,
      ).show(context, message: message, type: SnackBarType.success);

  static void showInfo(BuildContext context, {required String message}) =>
      SnackBarScope.of(
        context,
      ).show(context, message: message, type: SnackBarType.info);
}
