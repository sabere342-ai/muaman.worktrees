import 'dart:io';

int _u16(List<int> b, int off) => (b[off]) | (b[off + 1] << 8);

int _u32(List<int> b, int off) =>
    (b[off]) | (b[off + 1] << 8) | (b[off + 2] << 16) | (b[off + 3] << 24);

String _fmtUnix(int ts) {
  if (ts == 0) return '0 (zeroed)';
  final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true);
  return d.toIso8601String();
}

String _machineName(int m) {
  switch (m) {
    case 0x8664:
      return 'x64';
    case 0x014c:
      return 'x86';
    case 0xaa64:
      return 'arm64';
    default:
      return '0x${m.toRadixString(16)}';
  }
}

/// Read-only PE/COFF metadata reader used to explain release differences.
/// It never modifies the input files.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/pe_info.dart <file> [<file2> ...]');
    exitCode = 64;
    return;
  }
  for (final arg in args) {
    final file = File(arg);
    if (!file.existsSync()) {
      stderr.writeln('$arg: not found');
      continue;
    }
    final bytes = await file.readAsBytes();
    if (bytes.length < 0x40 || bytes[0] != 0x4D || bytes[1] != 0x5A) {
      stdout.writeln('$arg: not a PE image (missing MZ header)');
      continue;
    }
    final peOff = _u32(bytes, 0x3C);
    if (peOff + 24 + 68 > bytes.length) {
      stdout.writeln('$arg: truncated PE header (peOff=$peOff)');
      continue;
    }
    if (bytes[peOff] != 0x50 || bytes[peOff + 1] != 0x45) {
      stdout.writeln('$arg: no PE signature at $peOff');
      continue;
    }
    final opt = peOff + 24;
    final machine = _u16(bytes, peOff + 4);
    final timestamp = _u32(bytes, peOff + 8);
    final checksum = _u32(bytes, opt + 64);
    final sizeOfImage = _u32(bytes, opt + 56);
    final linker = _u16(bytes, opt + 2);
    final majorOs = _u16(bytes, opt + 40);
    final minorOs = _u16(bytes, opt + 42);
    stdout.writeln('$arg:');
    stdout.writeln('  machine=${_machineName(machine)} '
        'timestamp=$timestamp (${_fmtUnix(timestamp)})');
    stdout.writeln('  checksum=0x${checksum.toRadixString(16)} '
        'sizeOfImage=$sizeOfImage linker=$linker '
        'osVersion=$majorOs.$minorOs');
  }
}
