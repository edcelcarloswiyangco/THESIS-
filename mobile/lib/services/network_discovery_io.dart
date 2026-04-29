import 'dart:io';

Future<String?> discoverLocalApiBaseUrl() async {
  final localAddresses = await _findPrivateIpv4Addresses();

  if (localAddresses.isEmpty) {
    return await _probeCommonPrivateNetworks();
  }

  for (final localAddress in localAddresses) {
    final discovered = await _probeSubnet(localAddress);

    if (discovered != null) {
      return discovered;
    }
  }

  return await _probeCommonPrivateNetworks();
}

Future<List<InternetAddress>> _findPrivateIpv4Addresses() async {
  final interfaces = await NetworkInterface.list(
    includeLinkLocal: false,
    type: InternetAddressType.IPv4,
  );

  final candidates = <_InterfaceAddress>[];

  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      if (_isPrivateIpv4(address)) {
        candidates.add(
          _InterfaceAddress(
            address: address,
            priority: _interfacePriority(interface.name),
          ),
        );
      }
    }
  }

  candidates.sort((left, right) {
    final priorityComparison = left.priority.compareTo(right.priority);

    if (priorityComparison != 0) {
      return priorityComparison;
    }

    return left.address.address.compareTo(right.address.address);
  });

  return candidates
      .map((candidate) => candidate.address)
      .toList(growable: false);
}

int _interfacePriority(String name) {
  final normalized = name.toLowerCase();

  if (normalized.contains('wlan') ||
      normalized.contains('wifi') ||
      normalized.contains('hotspot') ||
      normalized.contains('ap') ||
      normalized.contains('eth') ||
      normalized.startsWith('en')) {
    return 0;
  }

  if (normalized.contains('tun') ||
      normalized.contains('tap') ||
      normalized.contains('ppp') ||
      normalized.contains('vpn') ||
      normalized.contains('rmnet') ||
      normalized.contains('cell') ||
      normalized.contains('veth') ||
      normalized.contains('docker') ||
      normalized == 'lo') {
    return 2;
  }

  return 1;
}

Future<String?> _probeSubnet(InternetAddress localAddress) async {
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

  if (first == 100 && second >= 64 && second <= 127) {
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
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 1);

  try {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 2));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(const Duration(seconds: 2));

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

Future<String?> _probeCommonPrivateNetworks() async {
  const prefixes = <String>[
    '100.83.103',
    '192.168.1',
    '192.168.0',
    '192.168.43',
    '192.168.137',
    '192.168.100',
    '192.168.8',
    '10.0.2',
    '10.0.3',
    '10.0.0',
    '10.0.1',
    '10.0.4',
    '172.16.0',
    '172.20.0',
    '172.20.10',
    '172.31.0',
  ];

  for (final prefix in prefixes) {
    final results = await Future.wait(
      [1, 2, 10, 100, 101, 102, 254].map((octet) => _probeHost(prefix, octet)),
    );

    for (final result in results) {
      if (result != null) {
        return result;
      }
    }
  }

  return null;
}

class _InterfaceAddress {
  _InterfaceAddress({required this.address, required this.priority});

  final InternetAddress address;
  final int priority;
}
