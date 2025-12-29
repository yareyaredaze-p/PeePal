import '../models/pee_log.dart';
import '../models/pee_log_features.dart';
import '../models/hydration_recommendation.dart';
import 'feature_extractor.dart';
import 'decision_tree_trainer.dart';

/// Algorithm 3: Offline Prediction
/// Predicts personalized hydration recommendations in real time
class HydrationPredictor {
  HydrationPredictor._();
  static final HydrationPredictor instance = HydrationPredictor._();

  final FeatureExtractor _featureExtractor = FeatureExtractor.instance;
  final DecisionTreeTrainer _trainer = DecisionTreeTrainer.instance;

  /// Predict hydration recommendation based on current state
  /// Uses trained Decision Tree model for prediction
  Future<HydrationRecommendation> predict({
    required int userId,
    required List<PeeLog> allLogs,
    required List<PeeLog> todayLogs,
  }) async {
    // If no logs, return no data recommendation
    if (allLogs.isEmpty) {
      return HydrationRecommendation.noData();
    }

    // Load or create model
    DecisionTreeModel? model = await _trainer.loadModel(userId);

    // If no model exists, train one
    if (model == null) {
      final features = _featureExtractor.extractFeatures(allLogs);
      if (features.isNotEmpty) {
        model = await _trainer.trainAndSave(features, userId);
      } else {
        model = DecisionTreeModel.defaultModel();
      }
    }

    // Compute current state features
    final lastLog = allLogs.isNotEmpty ? allLogs.first : null;
    final currentFeatures = _featureExtractor.computeCurrentStateFeatures(
      userId: userId,
      todayLogs: todayLogs,
      lastLog: lastLog,
    );

    // Make prediction
    final prediction = model.predict(currentFeatures);
    final explanation = model.getExplanation(currentFeatures, prediction);

    // Calculate confidence based on gap from threshold
    final double confidence = _calculateConfidence(currentFeatures, model);

    if (prediction == 1) {
      return HydrationRecommendation.drinkWater(
        explanation: explanation,
        confidence: confidence,
      );
    } else {
      return HydrationRecommendation.hydrationOK(
        explanation: explanation,
        confidence: confidence,
      );
    }
  }

  /// Retrain model with new data
  Future<void> retrainModel(int userId, List<PeeLog> logs) async {
    if (logs.isEmpty) return;

    final features = _featureExtractor.extractFeatures(logs);
    if (features.isNotEmpty) {
      await _trainer.trainAndSave(features, userId);
    }
  }

  /// Calculate prediction confidence
  double _calculateConfidence(
    PeeLogFeatures features,
    DecisionTreeModel model,
  ) {
    // Confidence is higher when the feature values are far from thresholds

    final gapDistance = (features.gapMinutes - model.gapThreshold).abs();
    final gapConfidence = (gapDistance / model.gapThreshold).clamp(0.0, 1.0);

    final countDistance = (features.dailyCount - model.countThreshold)
        .abs()
        .toDouble();
    final countConfidence = (countDistance / model.countThreshold).clamp(
      0.0,
      1.0,
    );

    // Weighted average based on feature importance
    return (gapConfidence * model.gapImportance +
            countConfidence * model.countImportance) *
        100;
  }

  /// Get model info for display
  Future<Map<String, dynamic>?> getModelInfo(int userId) async {
    final model = await _trainer.loadModel(userId);
    if (model == null) return null;

    return {
      'gapThreshold': model.gapThreshold,
      'countThreshold': model.countThreshold,
      'trainedAt': model.trainedAt,
      'trainingSize': model.trainingSize,
      'featureImportance': {
        'gapMinutes': model.gapImportance,
        'hourOfDay': model.hourImportance,
        'dailyCount': model.countImportance,
      },
    };
  }
}
