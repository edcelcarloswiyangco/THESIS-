import 'dart:io';

Future<String?> discoverLocalApiBaseUrl() async {
  final localAddress = await _findLocalIpv4Address();

  if (localAddress == null) {
    return null;
  }

  final octets = localAddress.address.split('.');

  if (octets.length != 4) {
    return null;
  }

  final prefix = '${octets[0]}.${octets[1]}.${octets[2]}';
  final lastOctet = int.tryParse(octets[3]) ?? -1;
  final candidates = _candidateOctets(lastOctet);

  for (final octetBatch in _batchCandidates(candidates, 20)) {
    final results = await Future.wait(
      octetBatch.map((octet) => _probeHost(prefix, octet)),
    );

    for (final result in results) {
      if (result != null) {
        return result;
      }
    }
  }

  return null;
}

Future<InternetAddress?> _findLocalIpv4Address() async {
  final interfaces = await NetworkInterface.list(
    includeLinkLocal: false,
    type: InternetAddressType.IPv4,
  );

  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      if (_isPrivateIpv4(address)) {
        return address;
      }
    }
  }

  return null;
}

bool _isPrivateIpv4(InternetAddress address) {
  final octets = address.address.split('.');

  if (octets.length != 4) {
    return false;
  }

  final first = int.tryParse(octets[0]) ?? -1;
  final second = int.tryParse(octets[1]) ?? -1;

  if (first == 10) {
    return true;
  }

  if (first == 172 && second >= 16 && second <= 31) {
    return true;
  }

  if (first == 192 && second == 168) {
    return true;
  }

  return false;
}

List<int> _candidateOctets(int localOctet) {
  final ordered = <int>{
    if (localOctet > 0) localOctet,
    if (localOctet > 1) localOctet - 1,
    if (localOctet < 254) localOctet + 1,
    1,
    2,
    10,
    100,
    101,
    102,
    254,
  };

  for (var octet = 1; octet <= 254; octet++) {
    ordered.add(octet);
  }

  return ordered.toList(growable: false);
}

Iterable<List<int>> _batchCandidates(
  List<int> candidates,
  int batchSize,
) sync* {
  for (var index = 0; index < candidates.length; index += batchSize) {
    yield candidates.sublist(
      index,
      index + batchSize > candidates.length
          ? candidates.length
          : index + batchSize,
    );
  }
}

Future<String?> _probeHost(String prefix, int octet) async {
  final uri = Uri.parse('http://$prefix.$octet:8000/api/health');
  final client = HttpClient()
    ..connectionTimeout = const Duration(milliseconds: 400);

  try {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(milliseconds: 600));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(
      const Duration(milliseconds: 800),
    );

    if (response.statusCode == 200) {
      return 'http://$prefix.$octet:8000/api';
    }
  } catch (_) {
    // Ignore probe failures and keep scanning the local subnet.
  } finally {
    client.close(force: true);
  }

  return null;
}
