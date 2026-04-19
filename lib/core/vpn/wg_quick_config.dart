/// Returns the `Endpoint = host:port` value from a wg-quick INI, or null if missing.
String? parseWireGuardEndpoint(String wgQuickConfig) {
  final m = RegExp(
    r'^\s*Endpoint\s*=\s*(\S+)',
    multiLine: true,
    caseSensitive: false,
  ).firstMatch(wgQuickConfig);
  return m?.group(1);
}
