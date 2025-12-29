import '../models/hydration_recommendation.dart';
import 'database_service.dart';
import '../ml/feature_extractor.dart';
import '../ml/decision_tree_trainer.dart';
import '../ml/hydration_predictor.dart';

/// ML Service - Coordinates ML pipeline operations
/// Provides a clean interface for UI to interact with ML components
class MLService {
  static final MLService instance = MLService._init();
  final DatabaseService _db = DatabaseService.instance;
  final FeatureExtractor _featureExtractor = FeatureExtractor.instance;
  final DecisionTreeTrainer _trainer = DecisionTreeTrainer.instance;
  final HydrationPredictor _predictor = HydrationPredictor.instance;

  MLService._init();

  /// Get current hydration recommendation for a user
  Future<HydrationRecommendation> getRecommendation(int userId) async {
    // Fetch all logs and today's logs
    final allLogs = await _db.getPeeLogs(userId);
    final todayLogs = await _db.getPeeLogsForDate(userId, DateTime.now());

    return await _predictor.predict(
      userId: userId,
      allLogs: allLogs,
      todayLogs: todayLogs,
    );
  }

  /// Update model after new log is added
  Future<void> onNewLogAdded(int userId) async {
    final logs = await _db.getPeeLogs(userId);
    await _predictor.retrainModel(userId, logs);
  }

  /// Check if user has a trained model
  Future<bool> hasModel(int userId) async {
    return await _trainer.hasModel(userId);
  }

  /// Get model information for display
  Future<Map<String, dynamic>?> getModelInfo(int userId) async {
    return await _predictor.getModelInfo(userId);
  }

  /// Force model retraining
  Future<void> retrainModel(int userId) async {
    final logs = await _db.getPeeLogs(userId);
    if (logs.isNotEmpty) {
      final features = _featureExtractor.extractFeatures(logs);
      await _trainer.trainAndSave(features, userId);
    }
  }
}
