import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/back_button_app_bar.dart';

class RenovationEstimateScreen extends StatefulWidget {
  const RenovationEstimateScreen({super.key});

  @override
  State<RenovationEstimateScreen> createState() =>
      _RenovationEstimateScreenState();
}

class _RenovationEstimateScreenState extends State<RenovationEstimateScreen> {
  String? selectedType;
  String? selectedFinishingLevel;
  final TextEditingController areaController = TextEditingController();

  final List<String> propertyTypes = [
    'Apartment',
    'Villa',
    'Office',
    'Restaurant',
    'Shop',
  ];

  final List<String> finishingLevels = [
    'Moderate',
    'Economy',
    'Luxury',
  ];

  @override
  void dispose() {
    areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BackButtonAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Renovation Cost Estimation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.largePadding),

            // Property Type Dropdown
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Property Type',
                border: OutlineInputBorder(),
              ),
              items: propertyTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedType = newValue;
                });
              },
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Area Input
            TextFormField(
              controller: areaController,
              decoration: const InputDecoration(
                labelText: 'Area (m²)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Finishing Level Dropdown
            DropdownButtonFormField<String>(
              value: selectedFinishingLevel,
              decoration: const InputDecoration(
                labelText: 'Finishing Level',
                border: OutlineInputBorder(),
              ),
              items: finishingLevels.map((String level) {
                return DropdownMenuItem<String>(
                  value: level,
                  child: Text(level),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedFinishingLevel = newValue;
                });
              },
            ),
            const SizedBox(height: AppConstants.largePadding),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Calculate functionality will be added later
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Calculate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
