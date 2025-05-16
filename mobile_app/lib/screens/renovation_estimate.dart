import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/renovation_service.dart';
import '../utils/renovation_calculator.dart';

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
  final RenovationService _renovationService = RenovationService();
  bool _isLoading = false;
  Map<String, dynamic>? _prices;
  Map<String, dynamic>? _calculationResults;

  final List<String> propertyTypes = [
    'Apartment',
    'Villa',
    'Office',
    'Restaurant',
    'Shop',
  ];

  final List<String> finishingLevels = [
    'Standard',
    'Economy',
    'Luxury',
  ];

  Future<void> _calculateCost() async {
    if (selectedFinishingLevel == null || 
        selectedType == null || 
        areaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select finishing level, property type and enter area')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _prices = null;
      _calculationResults = null;
    });

    try {
      // Get prices from Firestore
      _prices = await _renovationService.getRenovationPrices(selectedFinishingLevel!);
      
      // Calculate costs using the calculator
      double area = double.parse(areaController.text);
      _calculationResults = RenovationCalculator.calculateTotalCost(
        area: area,
        prices: _prices!,
        propertyType: selectedType!,
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renovation Cost Estimation'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                onPressed: _isLoading ? null : _calculateCost,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Calculate'),
              ),
            ),

            if (_calculationResults != null) ...[
              const SizedBox(height: AppConstants.largePadding),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price Details ($selectedFinishingLevel)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      const SizedBox(height: AppConstants.defaultPadding),
                      Text('Paint Cost per m²: \$${_calculationResults!['perSquareMeter']['paint'].toStringAsFixed(2)}'),
                      Text('Flooring Cost per m²: \$${_calculationResults!['perSquareMeter']['flooring'].toStringAsFixed(2)}'),
                      Text('Furniture Cost per m²: \$${_calculationResults!['perSquareMeter']['furniture'].toStringAsFixed(2)}'),
                      const Divider(),
                      Text('Paint Total: \$${_calculationResults!['paintCost'].toStringAsFixed(2)}'),
                      Text('Flooring Total: \$${_calculationResults!['flooringCost'].toStringAsFixed(2)}'),
                      Text('Furniture Total: \$${_calculationResults!['furnitureCost'].toStringAsFixed(2)}'),
                      const Divider(),
                      Text(
                        'Total Cost: \$${_calculationResults!['totalCost'].toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
