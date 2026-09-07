import 'dart:typed_data';

/// Fit file header, for reference: https://developer.garmin.com/fit/protocol/
class FitHeader {
  const FitHeader({
    this.headerSize = 14,
    this.protocolVersion = 0x20,
    required this.profileVersion,
    required this.dataSize,
    this.dataType = '.FIT',
    this.crc = 0x0000,
  });

  final int headerSize;
  final int protocolVersion;
  final int profileVersion;
  final int dataSize;
  final String dataType;
  final int crc;

  Uint8List toBytes() {
    // Fit header preferred size is 14 bytes
    final bytes = Uint8List(14);
    final buffer = ByteData.sublistView(bytes);

    buffer.setUint8(0, headerSize);
    buffer.setUint8(1, protocolVersion);

    // Profile Version LSB byte[2]  - MSB byte[3]
    buffer.setUint16(2, profileVersion, Endian.little);
    buffer.setUint32(4, dataSize, Endian.little);

    final dtAscii = dataType.codeUnits;
    for (var i = 0; i < dtAscii.length; i++) {
      buffer.setUint8(8 + i, dtAscii[i]);
    }

    // CRC LSB byte[12]  - MSB byte[13]
    buffer.setUint16(12, crc, Endian.little);

    return bytes;
  }
}
