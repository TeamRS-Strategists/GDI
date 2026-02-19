class GestureResponse {
  final List<List<double>>? landmarks; // 21 normalized [x, y] pairs
  final String gesture;
  final double confidence;
  final String status;
  final String? action; // e.g. 'Volume Up', 'Play/Pause' — only set when triggered
  final int? framesCaptured;
  final int? targetFrames;

  GestureResponse({
    this.landmarks,
    required this.gesture,
    required this.confidence,
    required this.status,
    this.action,
    this.framesCaptured,
    this.targetFrames,
  });

  factory GestureResponse.fromJson(Map<String, dynamic> json) {
    // Parse landmarks: [[x1,y1], [x2,y2], ...]
    List<List<double>>? parsedLandmarks;
    if (json['landmarks'] != null) {
      parsedLandmarks = (json['landmarks'] as List)
          .map((pt) => (pt as List).map((v) => (v as num).toDouble()).toList())
          .toList();
    }

    return GestureResponse(
      landmarks: parsedLandmarks,
      gesture: json['gesture'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'active',
      action: json['action'] as String?,
      framesCaptured: json['frames_captured'] as int?,
      targetFrames: json['target_frames'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'landmarks': landmarks,
      'gesture': gesture,
      'confidence': confidence,
      'status': status,
      'action': action,
      'frames_captured': framesCaptured,
      'target_frames': targetFrames,
    };
  }

  /// Whether hand landmarks are present in this frame
  bool get hasHand => landmarks != null && landmarks!.isNotEmpty;

  factory GestureResponse.empty() {
    return GestureResponse(
      gesture: 'None',
      confidence: 0.0,
      status: 'disconnected',
    );
  }
}

class GestureConfig {
  final String name;
  final String action;
  final String actionType; // "preset" or "keyboard"
  final String keys; // e.g. "cmd+shift+a" for keyboard type
  final String iconPath;

  GestureConfig({
    required this.name,
    required this.action,
    this.actionType = 'preset',
    this.keys = '',
    this.iconPath = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'action': action,
        'action_type': actionType,
        'keys': keys,
        'iconPath': iconPath,
      };

  factory GestureConfig.fromJson(Map<String, dynamic> json) => GestureConfig(
        name: json['name'] ?? '',
        action: json['action'] ?? '',
        actionType: json['action_type'] ?? 'preset',
        keys: json['keys'] ?? '',
        iconPath: json['iconPath'] ?? '',
      );

  /// Display-friendly action label
  String get displayAction {
    if (actionType == 'keyboard' && keys.isNotEmpty) {
      return keys.toUpperCase();
    }
    return action;
  }
}
