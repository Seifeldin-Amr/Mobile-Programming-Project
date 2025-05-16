import 'package:flutter/material.dart';
import 'package:mobile_app/constants/app_constants.dart';
import 'package:mobile_app/services/renovation_service.dart';

class AdminRenovationCostAdjust extends StatefulWidget {
  @override
  _AdminRenovationCostAdjustState createState() =>
      _AdminRenovationCostAdjustState();
}

class _AdminRenovationCostAdjustState
    extends State<AdminRenovationCostAdjust> {
    String? selectedType;
    final TextEditingController paintController = TextEditingController();
    final TextEditingController flooringController = TextEditingController();
    final TextEditingController furnitureController = TextEditingController();
    final RenovationService _renovationService = RenovationService();
    bool _isLoading = false;

  final List<String> propertyTypes = [
    'Standard',
    'Luxury',
    'Economy'
  ];

  Future<void> _handleAdjust() async {
    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a finishing level')),
      );
      return;
    }

    // Validate input fields
    if (paintController.text.isEmpty ||
        flooringController.text.isEmpty ||
        furnitureController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all cost fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _renovationService.adjustRenovationCosts(
        finishingLevel: selectedType!,
        paintCost: double.parse(paintController.text),
        flooringCost: double.parse(flooringController.text),
        furnitureCost: double.parse(furnitureController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Renovation costs adjusted successfully')),
        );
        // Clear the form
        paintController.clear();
        flooringController.clear();
        furnitureController.clear();
        setState(() {
          selectedType = null;
        });
      }
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
    paintController.dispose();
    flooringController.dispose();
    furnitureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renovation Cost Adjust'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adjust Prices',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Finishing Level',
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
            
            TextFormField(
              controller: paintController,
              decoration: const InputDecoration(
                labelText: 'Paint Cost',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_paint),
              ),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            TextFormField(
              controller: flooringController,
              decoration: const InputDecoration(
                labelText: 'Flooring Cost',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            TextFormField(
              controller: furnitureController,
              decoration: const InputDecoration(
                labelText: 'Furniture Cost',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chair),
              ),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: AppConstants.defaultPadding * 2),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleAdjust,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Adjust',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            
            // Add some bottom padding to ensure content doesn't get cut off
            const SizedBox(height: AppConstants.defaultPadding),
          ],
        ),
      ),
    );
  }
}
