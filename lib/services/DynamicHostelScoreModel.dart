import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyp/services/HostelScoreModel.dart'; // Fallback

class DynamicHostelScoreModel {
  double _baseScore = 53.13; // Regression intercept baseline
  List<dynamic>? _trees;
  bool _isLoaded = false;
  
  // Singleton instance
  static final DynamicHostelScoreModel _instance = DynamicHostelScoreModel._internal();
  factory DynamicHostelScoreModel() => _instance;
  DynamicHostelScoreModel._internal() {
    initLocalModel();
  }

  void _parseModel(String jsonStr) {
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        _baseScore = (decoded['base_score'] as num?)?.toDouble() ?? 53.13;
        _trees = decoded['trees'] as List<dynamic>?;
        _isLoaded = _trees != null && _trees!.isNotEmpty;
      } else if (decoded is List<dynamic>) {
        // Fallback if raw list of trees
        _baseScore = 53.13;
        _trees = decoded;
        _isLoaded = _trees!.isNotEmpty;
      }
    } catch (e) {
      print("Failed to parse XGBoost model: $e");
    }
  }

  Future<void> initLocalModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedModel = prefs.getString('xgboost_model_json');
      
      // If cached model is old (lacks base_score), purge it to use the new 7-feature model
      if (cachedModel != null && cachedModel.contains('"base_score"')) {
        _parseModel(cachedModel);
      } else {
        if (cachedModel != null) {
          await prefs.remove('xgboost_model_json');
        }
        final localJson = await rootBundle.loadString('assets/ml/xgboost_model.json');
        _parseModel(localJson);
      }
    } catch (e) {
      print("Failed to initialize local XGBoost model: $e");
    }
  }

  Future<void> fetchLatestWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/Tanveer-Hussian/DwellSense/main/assets/ml/xgboost_model.json'));

      if (response.statusCode == 200) {
        _parseModel(response.body);
        prefs.setString('xgboost_model_json', response.body);
      }
    } catch (e) {
      print("Failed to fetch dynamic weights: $e");
    }
  }

  /// Evaluates the input features against the XGBoost trees.
  double predict(List<double> input) {
    if (!_isLoaded || _trees == null) {
      // Fallback to the hardcoded static model if dynamic model is unavailable
      return predictHostelScore(input);
    }
    
    // In XGBoost regression: prediction = base_score + sum(tree_leaves)
    double sum = _baseScore;
    for (var tree in _trees!) {
      sum += _evaluateTree(tree, input);
    }
    return sum.clamp(0.0, 100.0);
  }

  double _evaluateTree(dynamic node, List<double> input) {
    if (node.containsKey('leaf')) {
      return (node['leaf'] as num).toDouble();
    }
    
    String splitFeature = node['split'];
    int featureIndex = int.parse(splitFeature.replaceAll('f', '')); // 'f0' -> 0
    double splitCondition = (node['split_condition'] as num).toDouble();
    
    int nextNodeId;
    if (featureIndex < input.length && input[featureIndex] < splitCondition) {
      nextNodeId = node['yes'];
    } else {
      nextNodeId = node['no'];
    }
    
    // Find child node
    var children = node['children'] as List;
    var nextNode = children.firstWhere((c) => c['nodeid'] == nextNodeId, orElse: () => null);
    if (nextNode == null) return 0.0; // Should not happen in a valid tree
    
    return _evaluateTree(nextNode, input);
  }
}
