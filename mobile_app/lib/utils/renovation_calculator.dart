class RenovationCalculator {
  // Property type multipliers
  static const Map<String, double> propertyMultipliers = {
    'Apartment': 1.0,
    'Villa': 2.0,
    'Office': 3.0,
    'Restaurant': 4.0,
    'Shop': 3.5,
  };

  // Calculate total renovation cost based on area, prices, and property type
  static Map<String, dynamic> calculateTotalCost({
    required double area,
    required Map<String, dynamic> prices,
    required String propertyType,
  }) {
    // Get the multiplier for the property type
    double multiplier = propertyMultipliers[propertyType] ?? 1.0;

    // Calculate individual costs with property type multiplier
    double paintCost = (prices['painting'] as num) * area * multiplier;
    double flooringCost = (prices['flooring'] as num) * area * multiplier;
    double furnitureCost = (prices['furniture'] as num) * area * multiplier;
    
    // Calculate total cost
    double totalCost = paintCost + flooringCost + furnitureCost;

    // Return detailed breakdown
    return {
      'paintCost': paintCost,
      'flooringCost': flooringCost,
      'furnitureCost': furnitureCost,
      'totalCost': totalCost,
      'perSquareMeter': {
        'paint': (prices['painting'] as num) * multiplier,
        'flooring': (prices['flooring'] as num) * multiplier,
        'furniture': (prices['furniture'] as num) * multiplier,
      },
      'multiplier': multiplier,
    };
  }
} 