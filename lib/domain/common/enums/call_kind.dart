/// Media of a call.
enum CallKind {
  /// Voice only.
  audio,

  /// Voice and camera.
  video;

  /// Kind parsed from its API name (`AUDIO`); unknown values fall back to [audio].
  factory CallKind.fromJson(Object? name) =>
      values.firstWhere((kind) => kind.name == '$name'.toLowerCase(), orElse: () => CallKind.audio);

  /// Name the backend uses for this kind.
  String get apiName => name.toUpperCase();
}
