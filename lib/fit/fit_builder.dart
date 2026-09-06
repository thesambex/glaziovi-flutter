import 'dart:typed_data';

import 'package:glaziovi/fit/fit_header.dart';
import 'package:glaziovi/fit/fit_record.dart';
import 'package:glaziovi/fit/fit_utils.dart';

/// Class to create FIT files (WIP)
class FitBuilder {
  final _recordsBuffer = BytesBuilder();

  void writeField({required DateTime createdAt, required String deviceUuid}) {
    final serialNumber = deviceUuid.hashCode.abs() & 0xFFFFFFFF;

    final def = ByteData(6 + 4 * 3);
    def.setUint8(0, 0x40);
    def.setUint8(1, 0x00);
    def.setUint8(2, 0x00);
    def.setUint16(3, 0, Endian.little);
    def.setUint8(5, 4);

    def.setUint8(6, 0);
    def.setUint8(7, 1);
    def.setUint8(8, 0x00);
    def.setUint8(9, 1);
    def.setUint8(10, 2);
    def.setUint8(11, 0x84);
    def.setUint8(12, 4);
    def.setUint8(13, 4);
    def.setUint8(14, 0x86);
    // file_id.serial_number: field 3, four-byte uint32z.
    def.setUint8(15, 3);
    def.setUint8(16, 4);
    def.setUint8(17, 0x8C);

    _recordsBuffer.add(def.buffer.asUint8List());

    final data = ByteData(1 + 1 + 2 + 4 + 4);
    data.setUint8(0, 0x00);
    data.setUint8(1, 4);
    data.setUint16(2, 255, Endian.little);
    data.setUint32(4, FitUtils.toGarminTimestamp(createdAt), Endian.little);
    data.setUint32(8, serialNumber & 0xFFFFFFFF, Endian.little);

    _recordsBuffer.add(data.buffer.asUint8List());
  }

  void writeRecords(List<FitRecord> records) {
    if (records.isEmpty) return;

    final def = ByteData(6 + 6 * 3);
    def.setUint8(0, 0x41);
    def.setUint8(1, 0x00);
    def.setUint8(2, 0x00);
    def.setUint16(3, 20, Endian.little);
    def.setUint8(5, 6);

    def.setUint8(6, 253);
    def.setUint8(7, 4);
    def.setUint8(8, 0x86);
    def.setUint8(9, 0);
    def.setUint8(10, 4);
    def.setUint8(11, 0x85);
    def.setUint8(12, 1);
    def.setUint8(13, 4);
    def.setUint8(14, 0x85);
    def.setUint8(15, 2);
    def.setUint8(16, 2);
    def.setUint8(17, 0x84);
    def.setUint8(18, 6);
    def.setUint8(19, 2);
    def.setUint8(20, 0x84);
    def.setUint8(21, 3);
    def.setUint8(22, 1);
    def.setUint8(23, 0x02);

    _recordsBuffer.add(def.buffer.asUint8List());

    for (var record in records) {
      final data = ByteData(1 + 4 + 4 + 4 + 2 + 2 + 1);
      data.setUint8(0, 0x01);

      data.setUint32(
        1,
        FitUtils.toGarminTimestamp(record.timestamp),
        Endian.little,
      );

      data.setInt32(
        5,
        record.latitude != null
            ? FitUtils.degreesToSemicircles(record.latitude!)
            : 0x7FFFFFFF,
        Endian.little,
      );

      data.setInt32(
        9,
        record.longitude != null
            ? FitUtils.degreesToSemicircles(record.longitude!)
            : 0x7FFFFFFF,
        Endian.little,
      );

      final altValue = record.altitude != null
          ? ((record.altitude! + 500) * 5).round()
          : 0xFFFF;
      data.setUint16(13, altValue, Endian.little);

      final speedValue = record.speed != null
          ? (record.speed! * 1000).round()
          : 0xFFFF;
      data.setUint16(15, speedValue, Endian.little);
      data.setUint8(17, record.heartRate ?? 0xFF);

      _recordsBuffer.add(data.buffer.asUint8List());
    }
  }

  Uint8List build() {
    final bodyBytes = _recordsBuffer.toBytes();

    final headerBytes = FitHeader(
      profileVersion: 2130,
      dataSize: bodyBytes.length,
    ).toBytes();

    final fileContent = BytesBuilder()
      ..add(headerBytes)
      ..add(bodyBytes);

    final fullBytes = fileContent.toBytes();

    final crc = _calculateCRC(fullBytes);
    final crcBuffer = ByteData(2)..setUint16(0, crc, Endian.little);

    return (BytesBuilder()
          ..add(fullBytes)
          ..add(crcBuffer.buffer.asUint8List()))
        .toBytes();
  }

  int _calculateCRC(List<int> bytes) {
    final crcTable = [
      0x0000,
      0xCC01,
      0xD801,
      0x1400,
      0xF001,
      0x3C00,
      0x2800,
      0xE401,
      0xA001,
      0x6C00,
      0x7800,
      0xB401,
      0x5000,
      0x9C01,
      0x8801,
      0x4400,
    ];
    int crc = 0;
    for (var byte in bytes) {
      var tmp = crcTable[crc & 0xF];
      crc = (crc >> 4) ^ tmp ^ crcTable[byte & 0xF];
      tmp = crcTable[crc & 0xF];
      crc = (crc >> 4) ^ tmp ^ crcTable[(byte >> 4) & 0xF];
    }
    return crc;
  }
}
