import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';

void main() {
  testWidgets('App smoke test - basic environment verification', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        title: AppConstants.appName,
        theme: ThemeData(
          primaryColor: AppColors.primary,
        ),
        home: const Scaffold(
          body: Center(
            child: Text(AppConstants.appName),
          ),
        ),
      ),
    );

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('DwellSense'), findsOneWidget);
  });
}
