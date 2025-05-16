class RenovationCalculator {
  // Calculate total renovation cost based on area and prices
  static Map<String, dynamic> calculateTotalCost({
    required double area,
    required Map<String, dynamic> prices,
  }) {
    // Calculate individual costs
    double paintCost = (prices['painting'] as num) * area;
    double flooringCost = (prices['flooring'] as num) * area;
    double furnitureCost = (prices['furniture'] as num) * area;
    
    // Calculate total cost
    double totalCost = paintCost + flooringCost + furnitureCost;

    // Return detailed breakdown
    return {
      'paintCost': paintCost,
      'flooringCost': flooringCost,
      'furnitureCost': furnitureCost,
      'totalCost': totalCost,
      'perSquareMeter': {
        'paint': prices['painting'],
        'flooring': prices['flooring'],
        'furniture': prices['furniture'],
      },
    };
  }
} 