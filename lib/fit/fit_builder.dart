import 'dart:typed_data';

import 'package:glaziovi/fit/fit_file_type.dart';
import 'package:glaziovi/fit/fit_header.dart';
import 'package:glaziovi/fit/fit_record.dart';
import 'package:glaziovi/fit/fit_session.dart';
import 'package:glaziovi/fit/fit_utils.dart';

/// Builder to create FIT files. Check Profile.xlsx in FIT SDK and garmin docs (WIP)
class FitBuilder {
  final _recordsBuffer = BytesBuilder();

  void writeSession({required FitSession session}) {
    final def = ByteData(6 + 9 * 3);

    // Definition Message: 0100 0010 (0x42)
    def.setUint8(0, 0x42);

    def.setUint8(1, 0x00);
    def.setUint8(2, 0x00);
    def.setUint16(3, 18, Endian.little);
    def.setUint8(5, 9);

    /* Field definitions */

    // timestamp
    def.setUint8(6, 253);
    def.setUint8(7, 4);
    def.setUint8(8, 0x86);

    // start_time
    def.setUint8(9, 2);
    def.setUint8(10, 4);
    def.setUint8(11, 0x86);

    // total_elapsed_time
    def.setUint8(12, 7);
    def.setUint8(13, 4);
    def.setUint8(14, 0x86);

    // total_timer_time
    def.setUint8(15, 8);
    def.setUint8(16, 4);
    def.setUint8(17, 0x86);

    // total_distance
    def.setUint8(18, 9);
    def.setUint8(19, 4);
    def.setUint8(20, 0x86);

    // avg_speed
    def.setUint8(21, 14);
    def.setUint8(22, 2);
    def.setUint8(23, 0x84);

    // max_speed
    def.setUint8(24, 15);
    def.setUint8(25, 2);
    def.setUint8(26, 0x84);

    // sport
    def.setUint8(27, 5);
    def.setUint8(28, 1);
    def.setUint8(29, 0x00);

    // sub_sport
    def.setUint8(30, 6);
    def.setUint8(31, 1);
    def.setUint8(32, 0x00);

    _recordsBuffer.add(def.buffer.asUint8List());

    final data = ByteData(27);

    // Definition Message: 0100 0010 (0x42)
    data.setUint8(0, 0x02);

    data.setUint32(
      1,
      FitUtils.toGarminTimestamp(session.timestamp),
      Endian.little,
    );

    data.setUint32(
      5,
      FitUtils.toGarminTimestamp(session.startTime),
      Endian.little,
    );

    data.setUint32(9, session.totalElapsedTime, Endian.little);
    data.setUint32(13, session.totalTimerTime, Endian.little);

    data.setUint32(17, (session.totalDistance * 100).round(), Endian.little);

    final avgSpeedVal = session.avgSpeed != null
        ? (session.avgSpeed! * 1000).round()
        : 0xFFFF;
    data.setUint16(21, avgSpeedVal, Endian.little);

    final maxSpeedVal = session.maxSpeed != null
        ? (session.maxSpeed! * 1000).round()
        : 0xFFFF;
    data.setUint16(23, maxSpeedVal, Endian.little);

    data.setUint8(25, session.sport);
    data.setUint8(26, session.subSport);

    _recordsBuffer.add(data.buffer.asUint8List());
  }

  void writeField({
    required FitFileType fileType,
    required DateTime createdAt,
    required String deviceUuid,
  }) {
    // TODO: Improve serial number generation?
    final serialNumber = deviceUuid.hashCode.abs() & 0xFFFFFFFF;

    final def = ByteData(6 + 4 * 3);
    /* Record Normal Header, check Record Format in docs */

    // Normal Header: 1 byte bit field, Bit 7 (0100 0000 OR 0x40)
    def.setUint8(0, 0x40);

    // Definition message
    def.setUint8(1, 0x00);
    def.setUint8(2, 0x00);
    def.setUint16(3, 0, Endian.little);
    def.setUint8(5, 4);

    /* Field definitions */

    // file_id
    def.setUint8(6, 0);
    def.setUint8(7, 1);
    def.setUint8(8, 0x00);

    // manufacturer
    def.setUint8(9, 1);
    def.setUint8(10, 2);
    def.setUint8(11, 0x84);

    // time_created
    def.setUint8(12, 4);
    def.setUint8(13, 4);
    def.setUint8(14, 0x86);

    // serial_number
    def.setUint8(15, 3);
    def.setUint8(16, 4);
    def.setUint8(17, 0x8C);

    _recordsBuffer.add(def.buffer.asUint8List());

    final data = ByteData(12);
    data.setUint8(0, 0x00);
    data.setUint8(1, fileType.value);
    data.setUint16(2, 255, Endian.little);
    data.setUint32(4, FitUtils.toGarminTimestamp(createdAt), Endian.little);
    data.setUint32(8, serialNumber & 0xFFFFFFFF, Endian.little);

    _recordsBuffer.add(data.buffer.asUint8List());
  }

  void writeRecords(List<FitRecord> records) {
    if (records.isEmpty) return;

    final def = ByteData(6 + 5 * 3);

    // Local Message Type: 0100 0001 (0x41)
    def.setUint8(0, 0x41);

    // Definition message
    def.setUint8(1, 0x00);
    def.setUint8(2, 0x00);
    def.setUint16(3, 20, Endian.little);
    def.setUint8(5, 5);

    /* Field definitions (Check *record* in Profile.xlsx) */

    // timestamp
    def.setUint8(6, 253);
    def.setUint8(7, 4);
    def.setUint8(8, 0x86);

    // position_lat
    def.setUint8(9, 0);
    def.setUint8(10, 4);
    def.setUint8(11, 0x85);

    // position_long
    def.setUint8(12, 1);
    def.setUint8(13, 4);
    def.setUint8(14, 0x85);

    // altitude
    def.setUint8(15, 2);
    def.setUint8(16, 2);
    def.setUint8(17, 0x84);

    // speed
    def.setUint8(18, 6);
    def.setUint8(19, 2);
    def.setUint8(20, 0x84);

    _recordsBuffer.add(def.buffer.asUint8List());

    for (var record in records) {
      final data = ByteData(1 + 4 + 4 + 4 + 2 + 2);
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

      // Check Scale/Offset in garmin docs
      final altValue = record.altitude != null
          ? ((record.altitude! + 500) * 5).round()
          : 0xFFFF;
      data.setUint16(13, altValue, Endian.little);

      final speedValue = record.speed != null
          ? (record.speed! * 1000).round()
          : 0xFFFF;
      data.setUint16(15, speedValue, Endian.little);

      _recordsBuffer.add(data.buffer.asUint8List());
    }
  }

  Uint8List build() {
    final bodyBytes = _recordsBuffer.toBytes();

    final headerBytes = FitHeader(
      profileVersion: 2130,
      dataSize: bodyBytes.length,
    ).toBytes();

    ByteData.sublistView(
      headerBytes,
    ).setUint16(12, _calculateCRC(headerBytes.sublist(0, 12)), Endian.little);

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
