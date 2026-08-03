import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../tool/pe_inspect.dart';

/// Builds a minimal but structurally valid PE32 image used to exercise
/// `inspectPe`. Contains one .text section and one IMAGE_DEBUG_DIRECTORY
/// entry (type 16) so both the COFF timestamp and the debug-directory
/// timestamps are parseable.
Uint8List buildSyntheticPe32() {
  const int peOff = 0x40;
  final b = Uint8List(0x200 + 28);

  void w16(int off, int v) {
    b[off] = v & 0xFF;
    b[off + 1] = (v >> 8) & 0xFF;
  }

  void w32(int off, int v) {
    b[off] = v & 0xFF;
    b[off + 1] = (v >> 8) & 0xFF;
    b[off + 2] = (v >> 16) & 0xFF;
    b[off + 3] = (v >> 24) & 0xFF;
  }

  // MZ header + e_lfanew.
  b[0] = 0x4D;
  b[1] = 0x5A;
  w32(0x3C, peOff);

  // PE signature.
  b[peOff] = 0x50;
  b[peOff + 1] = 0x45;

  // COFF header (20 bytes).
  w16(peOff + 4, 0x8664); // Machine: x64
  w16(peOff + 6, 1); // NumberOfSections
  w32(peOff + 8, 0x11223344); // TimeDateStamp
  w32(peOff + 12, 0); // PointerToSymbolTable
  w32(peOff + 16, 0); // NumberOfSymbols
  w16(peOff + 20, 224); // SizeOfOptionalHeader
  w16(peOff + 22, 0x22); // Characteristics

  // Optional header (PE32, 224 bytes).
  const int opt = peOff + 24;
  w16(opt + 0, 0x10B); // Magic: PE32
  b[opt + 2] = 14; // MajorLinkerVersion
  b[opt + 3] = 51; // MinorLinkerVersion
  w16(opt + 40, 6); // MajorOperatingSystemVersion
  w16(opt + 42, 1); // MinorOperatingSystemVersion
  w32(opt + 56, 0x2000); // SizeOfImage
  w32(opt + 64, 0x12345678); // CheckSum
  w32(opt + 92, 16); // NumberOfRvaAndSizes
  // Data directory[6] = Debug.
  w32(opt + 96 + 6 * 8, 0x1000); // RVA
  w32(opt + 96 + 6 * 8 + 4, 28); // Size

  // Section table.
  const int section = opt + 224;
  b[section] = 0x2E; // '.'
  b[section + 1] = 0x74; // 't'
  b[section + 2] = 0x65; // 'e'
  b[section + 3] = 0x78; // 'x'
  b[section + 4] = 0x74; // 't'
  w32(section + 8, 0x1100); // VirtualSize
  w32(section + 12, 0x1000); // VirtualAddress
  w32(section + 16, 0x1000); // SizeOfRawData
  w32(section + 20, 0x200); // PointerToRawData

  // IMAGE_DEBUG_DIRECTORY at file offset 0x200.
  w32(0x200 + 0, 0); // Characteristics
  w32(0x200 + 4, 0x55667788); // TimeDateStamp
  w32(0x200 + 12, 16); // Type: IMAGE_DEBUG_TYPE_EXCEPTION
  return b;
}

void main() {
  group('pe_inspect: inspectPe', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pe_inspect_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('reads COFF and debug-directory timestamps', () async {
      final file = File('${tempDir.path}/sample.exe');
      await file.writeAsBytes(buildSyntheticPe32());
      final meta = inspectPe(file, fileName: 'sample.exe');

      expect(meta.fileName, 'sample.exe');
      expect(meta.sizeBytes, 0x200 + 28);
      expect(meta.machine, 0x8664);
      expect(meta.coffTimeDateStamp, 0x11223344);
      expect(meta.coffTimeDateStampOffset, 0x40 + 8);
      expect(meta.linkerVersion, 14 | (51 << 8));
      expect(meta.checksum, 0x12345678);
      expect(meta.sizeOfImage, 0x2000);
      expect(meta.osVersionMajor, 6);
      expect(meta.osVersionMinor, 1);
      expect(meta.debugEntries, hasLength(1));
      expect(meta.debugEntries.single.type, 16);
      expect(meta.debugEntries.single.timeDateStamp, 0x55667788);
      expect(meta.sha256, hasLength(64));
    });

    test('rejects a non-PE file', () async {
      final file = File('${tempDir.path}/not-pe.bin');
      await file.writeAsBytes(List<int>.generate(64, (i) => i));
      expect(() => inspectPe(file, fileName: 'not-pe.bin'),
          throwsA(isA<FormatException>()));
    });
  });

  group('pe_inspect: compareInspections', () {
    Map<String, dynamic> entry(String name, String sha, {int ts = 100}) => {
          'fileName': name,
          'sizeBytes': 100,
          'sha256': sha,
          'pe': {
            'coffTimeDateStamp': ts,
            'debugEntries': [
              {'timeDateStamp': ts},
            ],
          },
        };

    test('reports all files byte-identical for identical inputs', () {
      final e1 = entry('a.exe', 'aa', ts: 100);
      final e2 = entry('b.dll', 'bb', ts: 100);
      final report = compareInspections([e1, e2], [e1, e2]);
      expect(report['allFilesByteIdentical'], isTrue);
    });

    test('flags a size or hash difference', () {
      final run1 = [entry('a.exe', 'aa')];
      final run2 = [entry('a.exe', 'ab')];
      final report = compareInspections(run1, run2);
      expect(report['allFilesByteIdentical'], isFalse);
      final f = (report['files'] as List).single as Map<String, dynamic>;
      expect(f['sha256Equal'], isFalse);
      expect(f['byteIdentical'], isFalse);
    });

    test('flags files present in only one run', () {
      final run1 = [entry('a.exe', 'aa')];
      final run2 = <Map<String, dynamic>>[];
      final report = compareInspections(run1, run2);
      expect(report['allFilesByteIdentical'], isFalse);
      final f = (report['files'] as List).single as Map<String, dynamic>;
      expect(f['presentInRun2'], isFalse);
    });
  });
}
