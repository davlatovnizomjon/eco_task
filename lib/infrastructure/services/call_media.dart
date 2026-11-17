import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// What another participant says about their own devices (sent over the call signalling channel).
class RemoteDevices {
  /// True while their microphone is off.
  final bool muted;

  /// True while their camera is sending pictures.
  final bool video;

  /// Builds the devices state.
  const RemoteDevices({this.muted = false, this.video = false});
}

/// The audio/video side of one call: a full mesh of WebRTC peer connections (one per other participant), the local
/// microphone and camera, and the remote pictures to draw. Signalling travels through [send] (the personal socket);
/// the server only relays it between people of the same live call.
///
/// Wire format of a signal (`data` of `call.signal`): `{t: offer|answer, sdp}`, `{t: ice, c, mid, idx}` and
/// `{t: state, muted, video}`. The person who joins a call offers to everybody already in it.
class CallMedia {
  /// Relays [data] to the participant [to].
  final void Function(String to, Map<String, dynamic> data) send;

  /// Builds the media layer; nothing is captured until [open].
  CallMedia({required this.send});

  /// Public STUN servers; a TURN server belongs here once the deployment has one.
  static const _config = <String, dynamic>{
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  /// Bumped whenever a picture or a remote device state changes, so views rebuild.
  final ValueNotifier<int> changes = ValueNotifier(0);

  /// Picture of the signed-in person's own camera.
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();

  /// Pictures and sound of the other participants, by account id.
  final Map<String, RTCVideoRenderer> remoteRenderers = {};

  /// Microphone and camera state the other participants reported, by account id.
  final Map<String, RemoteDevices> remoteDevices = {};

  final Map<String, RTCPeerConnection> _peers = {};
  final Map<String, List<RTCIceCandidate>> _pendingIce = {};
  MediaStream? _local;
  bool _opened = false;
  bool _disposed = false;

  /// True while the microphone is off.
  bool muted = false;

  /// True while the camera is sending.
  bool videoOn = false;

  /// True while the front camera is in use.
  bool frontCamera = true;

  /// True while the loudspeaker is on.
  bool speakerOn = false;

  /// Captures the microphone (and the camera when [video]); call once before talking to anybody.
  Future<void> open({required bool video}) async {
    if (_opened) return;
    _opened = true;
    await localRenderer.initialize();
    _local = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video ? {'facingMode': 'user'} : false,
    });
    videoOn = video;
    localRenderer.srcObject = _local;
    speakerOn = video;
    await Helper.setSpeakerphoneOn(speakerOn);
    _changed();
  }

  /// Starts talking to [userId]: creates the connection and sends an offer (the joiner's job).
  Future<void> connectTo(String userId) async {
    if (!_opened || _disposed || _peers.containsKey(userId)) return;
    final peer = await _peer(userId);
    await _offer(userId, peer);
  }

  /// Handles one signal from [from].
  Future<void> onSignal(String from, Map<String, dynamic> data) async {
    if (!_opened || _disposed) return;
    switch (data['t']) {
      case 'offer':
        final peer = _peers[from] ?? await _peer(from);
        await peer.setRemoteDescription(RTCSessionDescription('${data['sdp']}', 'offer'));
        await _drainIce(from, peer);
        final answer = await peer.createAnswer();
        await peer.setLocalDescription(answer);
        send(from, {'t': 'answer', 'sdp': answer.sdp});
        _sendState(from);
      case 'answer':
        final peer = _peers[from];
        if (peer == null) return;
        await peer.setRemoteDescription(RTCSessionDescription('${data['sdp']}', 'answer'));
        await _drainIce(from, peer);
      case 'ice':
        final candidate = RTCIceCandidate('${data['c']}', '${data['mid']}', (data['idx'] as num?)?.toInt());
        final peer = _peers[from];
        if (peer != null && await peer.getRemoteDescription() != null) {
          await peer.addCandidate(candidate);
        } else {
          _pendingIce.putIfAbsent(from, () => []).add(candidate);
        }
      case 'state':
        remoteDevices[from] = RemoteDevices(muted: data['muted'] == true, video: data['video'] == true);
        _changed();
    }
  }

  /// Forgets the participant [userId] (they left): closes their connection and picture.
  Future<void> drop(String userId) async {
    await _peers.remove(userId)?.close();
    _pendingIce.remove(userId);
    final renderer = remoteRenderers.remove(userId);
    renderer?.srcObject = null;
    await renderer?.dispose();
    remoteDevices.remove(userId);
    _changed();
  }

  /// Turns the microphone off or on and tells everybody.
  void setMuted(bool value) {
    muted = value;
    for (final t in _local?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      t.enabled = !value;
    }
    _broadcastState();
    _changed();
  }

  /// Turns the camera on or off. Switching it on in a voice call captures it and renegotiates every connection.
  Future<void> setVideo(bool value) async {
    final local = _local;
    if (local == null) return;
    if (value && local.getVideoTracks().isEmpty) {
      final cam = await navigator.mediaDevices.getUserMedia({
        'video': {'facingMode': frontCamera ? 'user' : 'environment'},
      });
      final track = cam.getVideoTracks().first;
      await local.addTrack(track);
      for (final entry in _peers.entries) {
        await entry.value.addTrack(track, local);
        await _offer(entry.key, entry.value);
      }
      localRenderer.srcObject = local;
    }
    for (final t in local.getVideoTracks()) {
      t.enabled = value;
    }
    videoOn = value;
    _broadcastState();
    _changed();
  }

  /// Switches between the front and the back camera.
  Future<void> flipCamera() async {
    final tracks = _local?.getVideoTracks() ?? const <MediaStreamTrack>[];
    if (tracks.isEmpty) return;
    await Helper.switchCamera(tracks.first);
    frontCamera = !frontCamera;
    _changed();
  }

  /// Switches the loudspeaker on or off.
  Future<void> setSpeaker(bool value) async {
    speakerOn = value;
    await Helper.setSpeakerphoneOn(value);
    _changed();
  }

  /// Closes every connection and releases the microphone and the camera.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final peer in _peers.values) {
      await peer.close();
    }
    _peers.clear();
    for (final renderer in remoteRenderers.values) {
      renderer.srcObject = null;
      await renderer.dispose();
    }
    remoteRenderers.clear();
    for (final track in _local?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _local?.dispose();
    localRenderer.srcObject = null;
    await localRenderer.dispose();
    changes.dispose();
  }

  /// Creates the connection to [userId] with the local tracks attached and the remote picture wired.
  Future<RTCPeerConnection> _peer(String userId) async {
    final peer = await createPeerConnection(_config);
    _peers[userId] = peer;
    final local = _local;
    if (local != null) {
      for (final track in local.getTracks()) {
        await peer.addTrack(track, local);
      }
    }
    peer.onIceCandidate = (c) {
      if (c.candidate == null) return;
      send(userId, {'t': 'ice', 'c': c.candidate, 'mid': c.sdpMid, 'idx': c.sdpMLineIndex});
    };
    peer.onTrack = (event) async {
      if (event.streams.isEmpty || _disposed) return;
      var renderer = remoteRenderers[userId];
      if (renderer == null) {
        renderer = RTCVideoRenderer();
        await renderer.initialize();
        remoteRenderers[userId] = renderer;
      }
      renderer.srcObject = event.streams.first;
      _changed();
    };
    return peer;
  }

  /// Sends an offer to [userId] on [peer] and our device state right after.
  Future<void> _offer(String userId, RTCPeerConnection peer) async {
    final offer = await peer.createOffer();
    await peer.setLocalDescription(offer);
    send(userId, {'t': 'offer', 'sdp': offer.sdp});
    _sendState(userId);
  }

  /// Adds the candidates that arrived before the remote description.
  Future<void> _drainIce(String userId, RTCPeerConnection peer) async {
    for (final candidate in _pendingIce.remove(userId) ?? const <RTCIceCandidate>[]) {
      await peer.addCandidate(candidate);
    }
  }

  void _sendState(String userId) => send(userId, {'t': 'state', 'muted': muted, 'video': videoOn});

  void _broadcastState() => _peers.keys.forEach(_sendState);

  void _changed() {
    if (!_disposed) changes.value++;
  }
}
