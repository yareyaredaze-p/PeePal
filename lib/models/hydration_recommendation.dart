/// ML prediction result for hydration recommendation
class HydrationRecommendation {
  final int prediction; // 0 = OK, 1 = Drink Water
  final String message; // User-facing message
  final String explanation; // Detailed explanation for understanding
  final double? confidence; // Optional confidence score

  HydrationRecommendation({
    required this.prediction,
    required this.message,
    required this.explanation,
    this.confidence,
  });

  /// Check if user should drink water
  bool get shouldDrinkWater => prediction == 1;

  /// Factory for "Drink Water" recommendation
  factory HydrationRecommendation.drinkWater({
    required String explanation,
    double? confidence,
  }) {
    return HydrationRecommendation(
      prediction: 1,
      message: 'Time to hydrate!',
      explanation: explanation,
      confidence: confidence,
    );
  }

  /// Factory for "Hydration OK" recommendation
  factory HydrationRecommendation.hydrationOK({
    required String explanation,
    double? confidence,
  }) {
    return HydrationRecommendation(
      prediction: 0,
      message: 'Hydration OK',
      explanation: explanation,
      confidence: confidence,
    );
  }

  /// Factory for no data available
  factory HydrationRecommendation.noData() {
    return HydrationRecommendation(
      prediction: 0,
      message: 'Log your first pee!',
      explanation:
          'Start tracking to get personalized hydration recommendations.',
      confidence: null,
    );
  }

  @override
  String toString() {
    return 'HydrationRecommendation(prediction: $prediction, message: $message)';
  }
}
