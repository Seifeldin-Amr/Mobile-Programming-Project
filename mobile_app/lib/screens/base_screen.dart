import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showAppBar;
  final bool showBackButton;
  final Widget? floatingActionButton;

  const BaseScreen({
    Key? key,
    required this.title,
    required this.body,
    this.actions,
    this.showAppBar = true,
    this.showBackButton = true,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          showAppBar
              ? AppBar(
                title: Text(title),
                leading:
                    showBackButton
                        ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                        : null,
                actions: actions,
              )
              : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
