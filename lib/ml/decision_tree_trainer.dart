import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants/app_constants.dart';
import '../models/pee_log_features.dart';

/// Algorithm 2: Offline ML Training
/// Trains a lightweight Decision Tree model on the user's pee-log features
class DecisionTreeTrainer {
  DecisionTreeTrainer._();
  static final DecisionTreeTrainer instance = DecisionTreeTrainer._();

  // Decision Tree structure stored as a simple set of rules
  // For academic clarity, we implement a basic decision tree manually

  /// Generate labels using rule-based heuristic:
  /// - 1 (Drink Water): gap_minutes > threshold OR daily_count < expected_count
  /// - 0 (Hydration OK): Otherwise
  List<int> generateLabels(List<PeeLogFeatures> features) {
    return features.map((f) {
      // Rule-based labeling for training data
      if (f.gapMinutes > AppConstants.gapThresholdMinutes) {
        return 1; // Too long since last pee - drink water
      }
      if (f.dailyCount < AppConstants.expectedDailyCount) {
        // Check if it's late in the day with few pees
        if (f.hourOfDay >= 14 && f.dailyCount < 3) {
          return 1; // Behind on hydration for this time of day
        }
        if (f.hourOfDay >= 18 && f.dailyCount < 5) {
          return 1; // Behind on hydration for evening
        }
      }
      return 0; // Hydration OK
    }).toList();
  }

  /// Train a Decision Tree and save model locally
  /// We implement a simple decision tree with learned thresholds
  Future<DecisionTreeModel> trainAndSave(
    List<PeeLogFeatures> features,
    int userId,
  ) async {
    if (features.isEmpty) {
      // Return default model if no data
      return DecisionTreeModel.defaultModel();
    }

    final labels = generateLabels(features);

    // Compute optimal thresholds based on data distribution
    final gapValues = features.map((f) => f.gapMinutes).toList();
    final hourValues = features.map((f) => f.hourOfDay.toDouble()).toList();
    final countValues = features.map((f) => f.dailyCount.toDouble()).toList();

    // Find threshold that best separates classes
    final optimalGapThreshold = _findOptimalThreshold(gapValues, labels);
    final optimalCountThreshold = _findOptimalThreshold(countValues, labels);

    // Calculate feature importances (simple variance-based)
    final gapImportance = _calculateVariance(gapValues);
    final hourImportance = _calculateVariance(hourValues);
    final countImportance = _calculateVariance(countValues);
    final totalImportance = gapImportance + hourImportance + countImportance;

    final model = DecisionTreeModel(
      gapThreshold: optimalGapThreshold,
      countThreshold: optimalCountThreshold.toInt(),
      gapImportance: gapImportance / totalImportance,
      hourImportance: hourImportance / totalImportance,
      countImportance: countImportance / totalImportance,
      trainedAt: DateTime.now(),
      trainingSize: features.length,
    );

    // Save model to local storage
    await _saveModel(model, userId);

    return model;
  }

  /// Find optimal threshold using simple split evaluation
  double _findOptimalThreshold(List<double> values, List<int> labels) {
    if (values.isEmpty) return AppConstants.gapThresholdMinutes;

    final sortedValues = List<double>.from(values)..sort();
    double bestThreshold = sortedValues[sortedValues.length ~/ 2];
    double bestScore = 0;

    // Try several candidate thresholds
    for (int i = 1; i < sortedValues.length; i++) {
      final threshold = (sortedValues[i - 1] + sortedValues[i]) / 2;
      final score = _evaluateSplit(values, labels, threshold);
      if (score > bestScore) {
        bestScore = score;
        bestThreshold = threshold;
      }
    }

    return bestThreshold;
  }

  /// Evaluate a split threshold using information gain
  double _evaluateSplit(
    List<double> values,
    List<int> labels,
    double threshold,
  ) {
    int leftCount0 = 0, leftCount1 = 0;
    int rightCount0 = 0, rightCount1 = 0;

    for (int i = 0; i < values.length; i++) {
      if (values[i] <= threshold) {
        if (labels[i] == 0) {
          leftCount0++;
        } else {
          leftCount1++;
        }
      } else {
        if (labels[i] == 0) {
          rightCount0++;
        } else {
          rightCount1++;
        }
      }
    }

    // Calculate purity (simplified Gini impurity)
    final leftTotal = leftCount0 + leftCount1;
    final rightTotal = rightCount0 + rightCount1;

    if (leftTotal == 0 || rightTotal == 0) return 0;

    final leftPurity =
        1 - pow(leftCount0 / leftTotal, 2) - pow(leftCount1 / leftTotal, 2);
    final rightPurity =
        1 - pow(rightCount0 / rightTotal, 2) - pow(rightCount1 / rightTotal, 2);

    return 1 -
        (leftTotal * leftPurity + rightTotal * rightPurity) / values.length;
  }

  /// Calculate variance for feature importance
  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    return values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
        values.length;
  }

  /// Save model to SharedPreferences
  Future<void> _saveModel(DecisionTreeModel model, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${AppConstants.mlModelKey}_$userId';
    await prefs.setString(key, jsonEncode(model.toJson()));
  }

  /// Load model from SharedPreferences
  Future<DecisionTreeModel?> loadModel(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${AppConstants.mlModelKey}_$userId';
    final json = prefs.getString(key);
    if (json == null) return null;
    return DecisionTreeModel.fromJson(jsonDecode(json));
  }

  /// Check if model exists for user
  Future<bool> hasModel(int userId) async {
    final model = await loadModel(userId);
    return model != null;
  }
}

/// Decision Tree Model representation
/// Stores learned thresholds and feature importances
class DecisionTreeModel {
  final double gapThreshold;
  final int countThreshold;
  final double gapImportance;
  final double hourImportance;
  final double countImportance;
  final DateTime trainedAt;
  final int trainingSize;

  DecisionTreeModel({
    required this.gapThreshold,
    required this.countThreshold,
    required this.gapImportance,
    required this.hourImportance,
    required this.countImportance,
    required this.trainedAt,
    required this.trainingSize,
  });

  /// Default model with standard thresholds
  factory DecisionTreeModel.defaultModel() {
    return DecisionTreeModel(
      gapThreshold: AppConstants.gapThresholdMinutes,
      countThreshold: AppConstants.expectedDailyCount,
      gapImportance: 0.5,
      hourImportance: 0.2,
      countImportance: 0.3,
      trainedAt: DateTime.now(),
      trainingSize: 0,
    );
  }

  /// Create from JSON
  factory DecisionTreeModel.fromJson(Map<String, dynamic> json) {
    return DecisionTreeModel(
      gapThreshold: (json['gapThreshold'] as num).toDouble(),
      countThreshold: json['countThreshold'] as int,
      gapImportance: (json['gapImportance'] as num).toDouble(),
      hourImportance: (json['hourImportance'] as num).toDouble(),
      countImportance: (json['countImportance'] as num).toDouble(),
      trainedAt: DateTime.parse(json['trainedAt'] as String),
      trainingSize: json['trainingSize'] as int,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'gapThreshold': gapThreshold,
      'countThreshold': countThreshold,
      'gapImportance': gapImportance,
      'hourImportance': hourImportance,
      'countImportance': countImportance,
      'trainedAt': trainedAt.toIso8601String(),
      'trainingSize': trainingSize,
    };
  }

  /// Make prediction using the decision tree
  int predict(PeeLogFeatures features) {
    // Decision tree logic:
    // 1. If gap since last pee > threshold → Drink Water
    // 2. If daily count < threshold and it's afternoon/evening → Drink Water
    // 3. Otherwise → Hydration OK

    if (features.gapMinutes > gapThreshold) {
      return 1; // Drink Water
    }

    if (features.dailyCount < countThreshold) {
      // Time-based adjustment
      if (features.hourOfDay >= 14 &&
          features.dailyCount < countThreshold - 3) {
        return 1; // Behind schedule
      }
      if (features.hourOfDay >= 18 &&
          features.dailyCount < countThreshold - 1) {
        return 1; // Behind schedule
      }
    }

    return 0; // Hydration OK
  }

  /// Get explanation for the prediction
  String getExplanation(PeeLogFeatures features, int prediction) {
    final List<String> reasons = [];

    if (prediction == 1) {
      if (features.gapMinutes > gapThreshold) {
        final hours = (features.gapMinutes / 60).toStringAsFixed(1);
        reasons.add('It\'s been $hours hours since your last pee');
      }
      if (features.dailyCount < countThreshold) {
        reasons.add('You\'ve only peed ${features.dailyCount} times today');
      }
      if (features.hourOfDay >= 14 && features.dailyCount < 3) {
        reasons.add('It\'s afternoon and hydration is low');
      }
    } else {
      reasons.add('Your pee frequency is healthy');
      if (features.gapMinutes <= 60) {
        reasons.add('Recent activity detected');
      }
    }

    return '${reasons.join('. ')}.';
  }
}
