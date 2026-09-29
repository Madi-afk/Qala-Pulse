/// Push transport can be injected when Firebase credentials and native config exist.
/// Polling is the shipped transport; no Firebase initialization occurs implicitly.
abstract interface class PushTransport {
  Future<void> registerDevice();
  Stream<String> get incidentIds;
  Future<void> dispose();
}

class DisabledPushTransport implements PushTransport {
  @override
  Future<void> registerDevice() async {}
  @override
  Stream<String> get incidentIds => const Stream.empty();
  @override
  Future<void> dispose() async {}
}
