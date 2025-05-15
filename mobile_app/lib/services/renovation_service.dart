import 'package:cloud_firestore/cloud_firestore.dart';

class RenovationService {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to adjust renovation costs
  Future<void> adjustRenovationCosts({
    required String finishingLevel,
    required double paintCost,
    required double flooringCost,
    required double furnitureCost,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (finishingLevel == 'Luxury') {
        updateData['painting'] = paintCost;
        updateData['flooring'] = flooringCost;
        updateData['furniture'] = furnitureCost;
         
        await _firestore
          .collection('renovation_prices')
          .doc('GDF3M52QJrwWJcCpGfNt')
          .update(updateData);
        
        print('Luxury Prices is updated');

      } else if (finishingLevel == 'Standard') {
        updateData['painting'] = paintCost;
        updateData['flooring'] = flooringCost;
        updateData['furniture'] = furnitureCost;
         
        await _firestore
          .collection('renovation_prices')
          .doc('WX6O6LKmOlgLErZZuur6')
          .update(updateData);

        print('Standard Prices is updated');
      } else if (finishingLevel == 'Economy') {
        updateData['painting'] = paintCost;
        updateData['flooring'] = flooringCost;
        updateData['furniture'] = furnitureCost;
         
        await _firestore
          .collection('renovation_prices')
          .doc('LQdtihnpYnjDP1VnoMdo')
          .update(updateData);

        print('Economy Prices is updated');
      }

    } catch (e) {
      throw Exception('Failed to adjust renovation costs: $e');
    }
  }
} 