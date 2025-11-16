import 'dart:ui';

/// Represents different types of commands sent from iOS to macOS
enum Command {
  cursorMove,
  tap,
  button,
  modeChange,
  mediaControl,
  pinch;

  Map<String, dynamic> toJson() {
    return {'type': name};
  }

  static Command fromJson(Map<String, dynamic> json) {
    return Command.values.firstWhere((e) => e.name == json['type']);
  }
}

/// Command for cursor movement
class CursorMoveCommand {
  final Offset delta;

  CursorMoveCommand({required this.delta});

  Map<String, dynamic> toJson() {
    return {
      'type': 'cursorMove',
      'delta': {
        'dx': delta.dx,
        'dy': delta.dy,
      },
    };
  }

  factory CursorMoveCommand.fromJson(Map<String, dynamic> json) {
    final deltaJson = json['delta'] as Map<String, dynamic>;
    return CursorMoveCommand(
      delta: Offset(
        (deltaJson['dx'] as num).toDouble(),
        (deltaJson['dy'] as num).toDouble(),
      ),
    );
  }
}

/// Types of click actions
enum ClickType {
  single,
  double_;

  String toJson() => name == 'double_' ? 'double' : name;

  static ClickType fromJson(String value) {
    return value == 'double' ? ClickType.double_ : ClickType.single;
  }
}

/// Command for tap actions
class TapCommand {
  final ClickType type;

  TapCommand({required this.type});

  Map<String, dynamic> toJson() {
    return {
      'type': 'tap',
      'clickType': type.toJson(),
    };
  }

  factory TapCommand.fromJson(Map<String, dynamic> json) {
    return TapCommand(
      type: ClickType.fromJson(json['clickType'] as String),
    );
  }
}

/// Button actions
enum ButtonAction {
  back,
  forward;

  String toJson() => name;

  static ButtonAction fromJson(String value) {
    return ButtonAction.values.firstWhere((e) => e.name == value);
  }
}

/// Command for button actions
class ButtonCommand {
  final ButtonAction action;

  ButtonCommand({required this.action});

  Map<String, dynamic> toJson() {
    return {
      'type': 'button',
      'action': action.toJson(),
    };
  }

  factory ButtonCommand.fromJson(Map<String, dynamic> json) {
    return ButtonCommand(
      action: ButtonAction.fromJson(json['action'] as String),
    );
  }
}

/// Control modes for the app
enum ControlMode {
  presentation,
  mediaControl,
  basicMouse;

  String toJson() => name;

  static ControlMode fromJson(String value) {
    return ControlMode.values.firstWhere((e) => e.name == value);
  }
}

/// Command for mode changes
class ModeChangeCommand {
  final ControlMode mode;

  ModeChangeCommand({required this.mode});

  Map<String, dynamic> toJson() {
    return {
      'type': 'modeChange',
      'mode': mode.toJson(),
    };
  }

  factory ModeChangeCommand.fromJson(Map<String, dynamic> json) {
    return ModeChangeCommand(
      mode: ControlMode.fromJson(json['mode'] as String),
    );
  }
}

/// Media control actions
enum MediaAction {
  playPause,
  volumeUp,
  volumeDown;

  String toJson() => name;

  static MediaAction fromJson(String value) {
    return MediaAction.values.firstWhere((e) => e.name == value);
  }
}

/// Command for media control
class MediaControlCommand {
  final MediaAction action;

  MediaControlCommand({required this.action});

  Map<String, dynamic> toJson() {
    return {
      'type': 'mediaControl',
      'action': action.toJson(),
    };
  }

  factory MediaControlCommand.fromJson(Map<String, dynamic> json) {
    return MediaControlCommand(
      action: MediaAction.fromJson(json['action'] as String),
    );
  }
}

/// Command for pinch gestures
class PinchCommand {
  final double scale;

  PinchCommand({required this.scale});

  Map<String, dynamic> toJson() {
    return {
      'type': 'pinch',
      'scale': scale,
    };
  }

  factory PinchCommand.fromJson(Map<String, dynamic> json) {
    return PinchCommand(
      scale: (json['scale'] as num).toDouble(),
    );
  }
}
