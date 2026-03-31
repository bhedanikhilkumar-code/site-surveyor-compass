import 'dart:io';
import 'dart:math';

void main() {
  const size = 1024;
  final img = Image(width: size, height: size);

  // Fill background - dark navy
  fillRect(img, color: ColorRgba8(15, 23, 42, 255));

  // Draw outer circle border
  drawCircleOutline(img, cx: size ~/ 2, cy: size ~/ 2, radius: 460, color: ColorRgba8(56, 189, 248, 255), thickness: 8);

  // Draw inner circle
  drawCircleOutline(img, cx: size ~/ 2, cy: size ~/ 2, radius: 380, color: ColorRgba8(100, 116, 139, 255), thickness: 3);

  // Draw tick marks
  for (int i = 0; i < 360; i += 5) {
    final rad = i * pi / 180;
    final cx = size / 2;
    final cy = size / 2;
    final innerR = i % 30 == 0 ? 340.0 : 360.0;
    final outerR = 380.0;
    final thickness = i % 90 == 0 ? 6 : (i % 30 == 0 ? 3 : 1);
    final tickColor = i == 0
        ? ColorRgba8(56, 189, 248, 255) // North = cyan
        : ColorRgba8(200, 200, 200, 255);

    final x1 = cx + innerR * sin(rad);
    final y1 = cy - innerR * cos(rad);
    final x2 = cx + outerR * sin(rad);
    final y2 = cy - outerR * cos(rad);

    drawLine(img, x1: x1, y1: y1, x2: x2, y2: y2, color: tickColor, thickness: thickness.toDouble());
  }

  // Draw cardinal direction letters
  // N at top (cyan)
  drawLargeLetter(img, 'N', cx: size / 2, cy: 200, color: ColorRgba8(56, 189, 248, 255));
  // S at bottom
  drawLargeLetter(img, 'S', cx: size / 2, cy: 824, color: ColorRgba8(255, 255, 255, 255));
  // E at right
  drawLargeLetter(img, 'E', cx: 824, cy: size / 2, color: ColorRgba8(255, 255, 255, 255));
  // W at left
  drawLargeLetter(img, 'W', cx: 200, cy: size / 2, color: ColorRgba8(255, 255, 255, 255));

  // Draw north arrow (red triangle at top)
  drawTriangle(img, x: size / 2, y: 270, width: 50, height: 120, color: ColorRgba8(239, 68, 68, 255));
  // South arrow (white)
  drawTriangle(img, x: size / 2, y: 754, width: 40, height: 80, color: ColorRgba8(255, 255, 255, 180), pointingDown: true);

  // Draw center dot
  fillCircle(img, cx: size ~/ 2, cy: size ~/ 2, radius: 12, color: ColorRgba8(255, 255, 255, 255));

  // Save
  final file = File('assets/images/compass_icon.png');
  file.writeAsBytesSync(encodePng(img));
  print('Icon saved to assets/images/compass_icon.png');
}

// Simple Image class for PNG generation
class Image {
  final int width;
  final int height;
  late final List<int> data;

  Image({required this.width, required this.height}) {
    data = List.filled(width * height * 4, 0);
  }

  void setPixel(int x, int y, ColorRgba8 color) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    final i = (y * width + x) * 4;
    // Blend with existing
    final sa = color.a / 255.0;
    final da = data[i + 3] / 255.0;
    final outA = sa + da * (1 - sa);
    if (outA > 0) {
      data[i] = ((color.r * sa + data[i] * da * (1 - sa)) / outA).round().clamp(0, 255);
      data[i + 1] = ((color.g * sa + data[i + 1] * da * (1 - sa)) / outA).round().clamp(0, 255);
      data[i + 2] = ((color.b * sa + data[i + 2] * da * (1 - sa)) / outA).round().clamp(0, 255);
    }
    data[i + 3] = (outA * 255).round().clamp(0, 255);
  }
}

class ColorRgba8 {
  final int r, g, b, a;
  const ColorRgba8(this.r, this.g, this.b, this.a);
}

void fillRect(Image img, {required ColorRgba8 color}) {
  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      final i = (y * img.width + x) * 4;
      img.data[i] = color.r;
      img.data[i + 1] = color.g;
      img.data[i + 2] = color.b;
      img.data[i + 3] = color.a;
    }
  }
}

void fillCircle(Image img, {required int cx, required int cy, required int radius, required ColorRgba8 color}) {
  for (int y = cy - radius; y <= cy + radius; y++) {
    for (int x = cx - radius; x <= cx + radius; x++) {
      final dx = x - cx;
      final dy = y - cy;
      if (dx * dx + dy * dy <= radius * radius) {
        img.setPixel(x, y, color);
      }
    }
  }
}

void drawCircleOutline(Image img, {required int cx, required int cy, required int radius, required ColorRgba8 color, required int thickness}) {
  for (int y = cy - radius - thickness; y <= cy + radius + thickness; y++) {
    for (int x = cx - radius - thickness; x <= cx + radius + thickness; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final dist = sqrt(dx * dx + dy * dy);
      if ((dist - radius).abs() <= thickness / 2) {
        img.setPixel(x, y, color);
      }
    }
  }
}

void drawLine(Image img, {required double x1, required double y1, required double x2, required double y2, required ColorRgba8 color, required double thickness}) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final len = sqrt(dx * dx + dy * dy);
  final steps = (len * 2).ceil();

  for (int i = 0; i <= steps; i++) {
    final t = i / steps;
    final x = x1 + dx * t;
    final y = y1 + dy * t;
    final r = (thickness / 2).ceil();
    for (int oy = -r; oy <= r; oy++) {
      for (int ox = -r; ox <= r; ox++) {
        if (ox * ox + oy * oy <= r * r) {
          img.setPixel(x.round() + ox, y.round() + oy, color);
        }
      }
    }
  }
}

void drawLargeLetter(Image img, String letter, {required double cx, required double cy, required ColorRgba8 color}) {
  // Simple block letters using filled rectangles
  final patterns = {
    'N': [
      [1,0,0,0,1],
      [1,1,0,0,1],
      [1,0,1,0,1],
      [1,0,0,1,1],
      [1,0,0,0,1],
    ],
    'S': [
      [0,1,1,1,0],
      [1,0,0,0,0],
      [0,1,1,0,0],
      [0,0,0,1,0],
      [1,1,1,0,0],
    ],
    'E': [
      [1,1,1,1,0],
      [1,0,0,0,0],
      [1,1,1,0,0],
      [1,0,0,0,0],
      [1,1,1,1,0],
    ],
    'W': [
      [1,0,0,0,1],
      [1,0,0,0,1],
      [1,0,1,0,1],
      [1,1,0,1,1],
      [1,0,0,0,1],
    ],
  };

  final pattern = patterns[letter];
  if (pattern == null) return;

  const pixelSize = 16;
  const gap = 2;
  final startX = cx - (pattern[0].length * (pixelSize + gap)) / 2;
  final startY = cy - (pattern.length * (pixelSize + gap)) / 2;

  for (int row = 0; row < pattern.length; row++) {
    for (int col = 0; col < pattern[row].length; col++) {
      if (pattern[row][col] == 1) {
        final px = (startX + col * (pixelSize + gap)).round();
        final py = (startY + row * (pixelSize + gap)).round();
        for (int dy = 0; dy < pixelSize; dy++) {
          for (int dx = 0; dx < pixelSize; dx++) {
            img.setPixel(px + dx, py + dy, color);
          }
        }
      }
    }
  }
}

void drawTriangle(Image img, {required double x, required double y, required double width, required double height, required ColorRgba8 color, bool pointingDown = false}) {
  for (int row = 0; row < height; row++) {
    final t = row / height;
    final halfW = (width / 2) * t;
    for (int col = (-halfW).round(); col <= halfW.round(); col++) {
      final px = x.round() + col;
      final py = pointingDown ? (y - height / 2 + row).round() : (y - height / 2 + row).round();
      img.setPixel(px, py, color);
    }
  }
}

List<int> encodePng(Image img) {
  // Minimal PNG encoder
  final bytes = <int>[];

  // PNG signature
  bytes.addAll([137, 80, 78, 71, 13, 10, 26, 10]);

  // IHDR
  final ihdr = <int>[];
  addInt32(ihdr, img.width);
  addInt32(ihdr, img.height);
  ihdr.addAll([8, 6, 0, 0, 0]); // 8-bit RGBA
  addChunk(bytes, 'IHDR', ihdr);

  // IDAT - compress with zlib
  final rawData = <int>[];
  for (int y = 0; y < img.height; y++) {
    rawData.add(0); // filter byte
    for (int x = 0; x < img.width; x++) {
      final i = (y * img.width + x) * 4;
      rawData.add(img.data[i]);
      rawData.add(img.data[i + 1]);
      rawData.add(img.data[i + 2]);
      rawData.add(img.data[i + 3]);
    }
  }
  final compressed = zlibEncode(rawData);
  addChunk(bytes, 'IDAT', compressed);

  // IEND
  addChunk(bytes, 'IEND', []);

  return bytes;
}

void addInt32(List<int> bytes, int value) {
  bytes.add((value >> 24) & 0xFF);
  bytes.add((value >> 16) & 0xFF);
  bytes.add((value >> 8) & 0xFF);
  bytes.add(value & 0xFF);
}

void addChunk(List<int> bytes, String type, List<int> data) {
  final chunk = <int>[];
  chunk.addAll(type.codeUnits);
  chunk.addAll(data);

  addInt32(bytes, data.length);

  // CRC
  final crcData = <int>[];
  crcData.addAll(type.codeUnits);
  crcData.addAll(data);
  final crc = crc32(crcData);

  bytes.addAll(chunk);
  addInt32(bytes, crc);
}

// CRC32 implementation
int crc32(List<int> data) {
  int crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (int i = 0; i < 8; i++) {
      if ((crc & 1) != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc ^ 0xFFFFFFFF;
}

// Zlib encoder (deflate with zlib header)
List<int> zlibEncode(List<int> data) {
  final output = <int>[];

  // Zlib header
  output.add(0x78); // CMF
  output.add(0x01); // FLG

  // Store blocks
  const blockSize = 65535;
  int offset = 0;
  while (offset < data.length) {
    final remaining = data.length - offset;
    final len = remaining > blockSize ? blockSize : remaining;
    final isLast = (offset + len >= data.length);

    output.add(isLast ? 1 : 0); // BFINAL
    output.add(len & 0xFF);
    output.add((len >> 8) & 0xFF);
    output.add((~len) & 0xFF);
    output.add(((~len) >> 8) & 0xFF);

    for (int i = 0; i < len; i++) {
      output.add(data[offset + i]);
    }
    offset += len;
  }

  // Adler32 checksum
  int a = 1, b = 0;
  for (final byte in data) {
    a = (a + byte) % 65521;
    b = (b + a) % 65521;
  }
  output.add((b >> 8) & 0xFF);
  output.add(b & 0xFF);
  output.add((a >> 8) & 0xFF);
  output.add(a & 0xFF);

  return output;
}
