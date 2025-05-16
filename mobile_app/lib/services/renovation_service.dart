import 'package:cloud_firestore/cloud_firestore.dart';

class RenovationService {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to get renovation prices based on finishing level
  Future<Map<String, dynamic>> getRenovationPrices(String finishingLevel) async {
    try {
      String documentId;
      switch (finishingLevel) {
        case 'Luxury':
          documentId = 'GDF3M52QJrwWJcCpGfNt';
          break;
        case 'Standard':
          documentId = 'WX6O6LKmOlgLErZZuur6';
          break;
        case 'Economy':
          documentId = 'LQdtihnpYnjDP1VnoMdo';
          break;
        default:
          throw Exception('Invalid finishing level');
      }

      DocumentSnapshot doc = await _firestore
          .collection('renovation_prices')
          .doc(documentId)
          .get();

      if (!doc.exists) {
        throw Exception('Prices not found for $finishingLevel level');
      }

      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch renovation prices: $e');
    }
  }

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