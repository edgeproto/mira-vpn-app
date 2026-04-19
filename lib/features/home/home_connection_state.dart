/// VPN connection phase shown on the Home screen (backed by [VpnController] on supported platforms).
enum HomeConnectionState {
  disconnected,
  preparing,
  connecting,
  connected,
  error,
}
