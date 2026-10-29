import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/story_project.dart';

class ExportService {
  static Future<Uint8List> generateBeatWorkTimelinePdf(
    StoryProject project,
  ) async {
    final pdf = pw.Document();
    final courier = pw.Font.courier();
    final courierBold = pw.Font.courierBold();
    final courierOblique = pw.Font.courierOblique();
    final collected = project.getCollectedTimeline();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(72, 64, 72, 64),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                alignment: pw.Alignment.topRight,
                margin: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Text(
                  '${context.pageNumber}.',
                  style: pw.TextStyle(font: courier, fontSize: 10),
                ),
              ),
        build: (_) {
          final widgets = <pw.Widget>[
            pw.SizedBox(height: 32),
            pw.Center(
              child: pw.Text(
                project.title.toUpperCase(),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: courierBold, fontSize: 20),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'written by ${project.author}',
                style: pw.TextStyle(font: courier, fontSize: 12),
              ),
            ),
            if (project.logline.trim().isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Center(
                child: pw.Text(
                  '"${project.logline.trim()}"',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: courierOblique, fontSize: 11),
                ),
              ),
            ],
            pw.SizedBox(height: 28),
            pw.Divider(thickness: 1.5),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Copyright © ${DateTime.now().year} BeatWork ScriptWriter',
                style: pw.TextStyle(font: courier, fontSize: 9),
              ),
            ),
            pw.SizedBox(height: 26),
          ];

          String? currentBeatId;
          for (final entry in collected) {
            final version = entry.scene.activeVersion;
            if (entry.beat.id != currentBeatId) {
              currentBeatId = entry.beat.id;
              widgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 18, bottom: 10),
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  color: PdfColors.grey200,
                  child: pw.Text(
                    'BEAT ${entry.beat.number}: ${entry.beat.name.toUpperCase()}  |  ${entry.beat.act.title} - ${entry.beat.targetPage}',
                    style: pw.TextStyle(font: courierBold, fontSize: 9),
                  ),
                ),
              );
            }

            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 10, bottom: 5),
                child: pw.Text(
                  version.slugline.toUpperCase(),
                  style: pw.TextStyle(font: courierBold, fontSize: 12),
                ),
              ),
            );
            widgets.add(
              pw.Text(
                'Scene #${entry.overallIndex}  |  Version ${version.versionNumber}',
                style: pw.TextStyle(font: courierOblique, fontSize: 8),
              ),
            );
            if (version.summary.trim().isNotEmpty) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 5),
                  child: pw.Text(
                    'Summary: ${version.summary.trim()}',
                    style: pw.TextStyle(font: courier, fontSize: 9),
                  ),
                ),
              );
            }
            if (version.notes.trim().isNotEmpty) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.Text(
                    'Writer Notes: ${version.notes.trim()}',
                    style: pw.TextStyle(font: courierOblique, fontSize: 9),
                  ),
                ),
              );
            }
            if (entry.mappedEvents.isNotEmpty) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3, bottom: 5),
                  child: pw.Text(
                    'Events: ${entry.mappedEvents.map((event) => event.title).join('; ')}',
                    style: pw.TextStyle(font: courierOblique, fontSize: 9),
                  ),
                ),
              );
            } else {
              widgets.add(pw.SizedBox(height: 5));
            }

            for (final rawLine in _scriptBodyLines(
              version.scriptContent,
              version.slugline,
            )) {
              final line = rawLine.trim();
              if (line.isEmpty) {
                widgets.add(pw.SizedBox(height: 7));
              } else if (_isCharacterCue(line)) {
                widgets.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 8, left: 140),
                    child: pw.Text(
                      line.toUpperCase(),
                      style: pw.TextStyle(font: courierBold, fontSize: 11),
                    ),
                  ),
                );
              } else if (line.startsWith('(') && line.endsWith(')')) {
                widgets.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.only(left: 110),
                    child: pw.Text(
                      line,
                      style: pw.TextStyle(font: courier, fontSize: 11),
                    ),
                  ),
                );
              } else if (line.toUpperCase().endsWith('TO:') ||
                  line.toUpperCase().startsWith('FADE ')) {
                widgets.add(
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      line.toUpperCase(),
                      style: pw.TextStyle(font: courierBold, fontSize: 11),
                    ),
                  ),
                );
              } else {
                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      line,
                      style: pw.TextStyle(font: courier, fontSize: 11),
                    ),
                  ),
                );
              }
            }
            widgets.add(pw.SizedBox(height: 14));
          }

          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 30),
              child: pw.Center(
                child: pw.Text(
                  'THE END',
                  style: pw.TextStyle(font: courierBold, fontSize: 14),
                ),
              ),
            ),
          );
          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  static Future<String?> saveBeatWorkTimelinePdf(StoryProject project) async {
    final bytes = await generateBeatWorkTimelinePdf(project);
    final fileName =
        '${_sanitizeFileName(project.title)}_beatwork_timeline.pdf';

    try {
      final outputUri = await FilePicker.saveFile(
        dialogTitle: 'Export BeatWork Script Timeline PDF',
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (outputUri != null) return outputUri.toFilePath();
    } catch (error) {
      debugPrint('Timeline PDF save error: $error. Falling back to documents.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Generates industry standard Final Draft (.fdx) XML
  static String generateFinalDraftFdx(StoryProject project) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no" ?>');
    buffer.writeln(
      '<FinalDraft DocumentType="Script" Template="No" Version="4">',
    );
    buffer.writeln('  <HeaderAndFooter>');
    buffer.writeln('    <Header>');
    buffer.writeln(
      '      <Paragraph Alignment="Right" FirstIndent="0.00" Leading="Regular" LeftIndent="1.25" RightIndent="1.25" SpaceBefore="0" Spacing="1" StartsOnPage="1">',
    );
    buffer.writeln(
      '        <Text>${_escapeXml(project.title)} - Screenplay</Text>',
    );
    buffer.writeln('      </Paragraph>');
    buffer.writeln('    </Header>');
    buffer.writeln('    <Footer>');
    buffer.writeln(
      '      <Paragraph Alignment="Right" FirstIndent="0.00" Leading="Regular" LeftIndent="1.25" RightIndent="1.25" SpaceBefore="0" Spacing="1" StartsOnPage="1">',
    );
    buffer.writeln(
      '        <Text AdornmentStyle="0" Background="#FFFFFFFFFFFF" Color="#000000000000" Font="Courier Final Draft" RevisionID="0" Size="12" Style="">Page </Text>',
    );
    buffer.writeln('        <DynamicLabel Type="Page #"/>');
    buffer.writeln('      </Paragraph>');
    buffer.writeln('    </Footer>');
    buffer.writeln('  </HeaderAndFooter>');
    buffer.writeln('  <TitlePage>');
    buffer.writeln('    <Content>');
    buffer.writeln('      <Paragraph Type="Title">');
    buffer.writeln('        <Text>${_escapeXml(project.title)}</Text>');
    buffer.writeln('      </Paragraph>');
    buffer.writeln('      <Paragraph Type="Credit">');
    buffer.writeln('        <Text>Written by</Text>');
    buffer.writeln('      </Paragraph>');
    buffer.writeln('      <Paragraph Type="Author">');
    buffer.writeln('        <Text>${_escapeXml(project.author)}</Text>');
    buffer.writeln('      </Paragraph>');
    if (project.authorEmail.trim().isNotEmpty) {
      buffer.writeln('      <Paragraph Type="Contact">');
      buffer.writeln(
        '        <Text>${_escapeXml(project.authorEmail.trim())}</Text>',
      );
      buffer.writeln('      </Paragraph>');
    }
    buffer.writeln('    </Content>');
    buffer.writeln('  </TitlePage>');
    buffer.writeln('  <Content>');

    final collectedScenes = project.getCollectedTimeline();

    for (final entry in collectedScenes) {
      final version = entry.scene.activeVersion;

      // Scene Heading
      final slugline = version.slugline.trim().isNotEmpty
          ? version.slugline.trim().toUpperCase()
          : 'INT. UNTITLED SCENE - DAY';
      buffer.writeln('    <Paragraph Type="Scene Heading">');
      buffer.writeln(
        '      <Text AdornmentStyle="0" Background="#FFFFFFFFFFFF" Color="#000000000000" Font="Courier Final Draft" RevisionID="0" Size="12" Style="Bold">',
      );
      buffer.writeln('        ${_escapeXml(slugline)}');
      buffer.writeln('      </Text>');
      buffer.writeln('    </Paragraph>');

      // Script content parsed into Final Draft paragraph types
      for (final rawLine in _scriptBodyLines(
        version.scriptContent,
        version.slugline,
      )) {
        final line = rawLine.trim();
        if (line.isEmpty) continue;

        // Detect type
        final upper = line.toUpperCase();
        if (upper.startsWith('INT.') ||
            upper.startsWith('EXT.') ||
            upper.startsWith('INT/EXT') ||
            upper.startsWith('I/E')) {
          // Already handled or interior slug
          buffer.writeln('    <Paragraph Type="Scene Heading">');
          buffer.writeln('      <Text>${_escapeXml(upper)}</Text>');
          buffer.writeln('    </Paragraph>');
        } else if (line.startsWith('(') && line.endsWith(')')) {
          buffer.writeln('    <Paragraph Type="Parenthetical">');
          buffer.writeln('      <Text>${_escapeXml(line)}</Text>');
          buffer.writeln('    </Paragraph>');
        } else if (_isCharacterCue(line)) {
          buffer.writeln('    <Paragraph Type="Character">');
          buffer.writeln('      <Text>${_escapeXml(line)}</Text>');
          buffer.writeln('    </Paragraph>');
        } else if (upper.endsWith('TO:') || upper.startsWith('FADE ')) {
          buffer.writeln('    <Paragraph Type="Transition">');
          buffer.writeln('      <Text>${_escapeXml(upper)}</Text>');
          buffer.writeln('    </Paragraph>');
        } else {
          buffer.writeln('    <Paragraph Type="Action">');
          buffer.writeln('      <Text>${_escapeXml(line)}</Text>');
          buffer.writeln('    </Paragraph>');
        }
      }
    }

    buffer.writeln('  </Content>');
    buffer.writeln('</FinalDraft>');
    return buffer.toString();
  }

  /// Generates a Fountain screenplay script
  static String generateFountain(StoryProject project) {
    final buffer = StringBuffer();
    buffer.writeln('Title: ${project.title}');
    buffer.writeln('Credit: written by');
    buffer.writeln('Author: ${project.author}');
    if (project.authorEmail.trim().isNotEmpty) {
      buffer.writeln('Contact: ${project.authorEmail.trim()}');
    }
    buffer.writeln(
      'Draft date: ${DateTime.now().toLocal().toString().split(' ')[0]}',
    );
    buffer.writeln();
    buffer.writeln('===');
    buffer.writeln();

    final collectedScenes = project.getCollectedTimeline();

    for (final entry in collectedScenes) {
      final version = entry.scene.activeVersion;
      buffer.writeln(version.slugline.toUpperCase());
      buffer.writeln();
      if (version.scriptContent.trim().isNotEmpty) {
        buffer.writeln(version.scriptContent.trim());
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generates a formatted industry-standard Screenplay PDF document
  static Future<Uint8List> generateScreenplayPdf(StoryProject project) async {
    final pdf = pw.Document();

    final fontCourier = pw.Font.courier();
    final fontCourierBold = pw.Font.courierBold();
    final fontCourierOblique = pw.Font.courierOblique();

    // 1. Cover / Title Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(72),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Spacer(flex: 3),
              pw.Text(
                project.title.toUpperCase(),
                style: pw.TextStyle(
                  font: fontCourierBold,
                  fontSize: 24,
                  letterSpacing: 2,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'by',
                style: pw.TextStyle(font: fontCourier, fontSize: 14),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                project.author,
                style: pw.TextStyle(font: fontCourier, fontSize: 16),
              ),
              if (project.authorEmail.trim().isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  project.authorEmail.trim(),
                  style: pw.TextStyle(font: fontCourier, fontSize: 11),
                ),
              ],
              pw.SizedBox(height: 24),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  project.genre.toUpperCase(),
                  style: pw.TextStyle(
                    font: fontCourierBold,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.Spacer(flex: 2),
              if (project.logline.isNotEmpty)
                pw.Container(
                  width: 380,
                  child: pw.Text(
                    '"${project.logline}"',
                    style: pw.TextStyle(
                      font: fontCourierOblique,
                      fontSize: 11,
                      color: PdfColors.grey800,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              pw.Spacer(flex: 3),
            ],
          );
        },
      ),
    );

    // 2. Script Pages
    final collectedScenes = project.getCollectedTimeline();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.only(
          left: 108, // 1.5 in standard left margin for binding
          right: 72, // 1.0 in
          top: 72,
          bottom: 72,
        ),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.Container();
          return pw.Container(
            alignment: pw.Alignment.topRight,
            margin: const pw.EdgeInsets.only(bottom: 24),
            child: pw.Text(
              '${context.pageNumber}.',
              style: pw.TextStyle(font: fontCourier, fontSize: 11),
            ),
          );
        },
        build: (pw.Context context) {
          final List<pw.Widget> widgets = [];

          for (final entry in collectedScenes) {
            final version = entry.scene.activeVersion;

            // Slugline
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 14, bottom: 8),
                child: pw.Text(
                  version.slugline.toUpperCase(),
                  style: pw.TextStyle(font: fontCourierBold, fontSize: 12),
                ),
              ),
            );

            // Screenplay content lines
            for (final rawLine in _scriptBodyLines(
              version.scriptContent,
              version.slugline,
            )) {
              final line = rawLine.trim();
              if (line.isEmpty) {
                widgets.add(pw.SizedBox(height: 8));
                continue;
              }

              final upper = line.toUpperCase();
              if (_isCharacterCue(line)) {
                // Character dialogue heading (centered / 2.0 - 2.5 in indent)
                widgets.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 10, left: 140),
                    child: pw.Text(
                      upper,
                      style: pw.TextStyle(font: fontCourierBold, fontSize: 12),
                    ),
                  ),
                );
              } else if (line.startsWith('(') && line.endsWith(')')) {
                // Parenthetical
                widgets.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 2, left: 110),
                    child: pw.Text(
                      line,
                      style: pw.TextStyle(font: fontCourier, fontSize: 12),
                    ),
                  ),
                );
              } else if (upper.endsWith('TO:') || upper.startsWith('FADE ')) {
                // Transition
                widgets.add(
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 8),
                      child: pw.Text(
                        upper,
                        style: pw.TextStyle(
                          font: fontCourierBold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                // Action block
                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text(
                      line,
                      style: pw.TextStyle(font: fontCourier, fontSize: 12),
                    ),
                  ),
                );
              }
            }

            widgets.add(pw.SizedBox(height: 12));
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  /// Prompts user to save Final Draft file (.fdx) to their desktop
  static Future<String?> saveFinalDraftToFile(StoryProject project) async {
    final content = generateFinalDraftFdx(project);
    final bytes = Uint8List.fromList(utf8.encode(content));
    final defaultFileName = '${_sanitizeFileName(project.title)}_beatwork.fdx';

    try {
      final outputUri = await FilePicker.saveFile(
        dialogTitle: 'Export Final Draft Script (.fdx)',
        fileName: defaultFileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['fdx'],
      );

      if (outputUri != null) {
        return outputUri.toFilePath();
      }
    } catch (e) {
      debugPrint(
        'File picker save error: $e. Falling back to local documents.',
      );
    }

    // Fallback: write to documents directory
    final dir = await getApplicationDocumentsDirectory();
    final fallbackPath = '${dir.path}/$defaultFileName';
    final file = File(fallbackPath);
    await file.writeAsBytes(bytes);
    return fallbackPath;
  }

  /// Prompts user to save Screenplay PDF to their desktop
  static Future<String?> savePdfToFile(StoryProject project) async {
    final pdfBytes = await generateScreenplayPdf(project);
    final defaultFileName =
        '${_sanitizeFileName(project.title)}_screenplay.pdf';

    try {
      final outputUri = await FilePicker.saveFile(
        dialogTitle: 'Export Screenplay PDF',
        fileName: defaultFileName,
        bytes: pdfBytes,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputUri != null) {
        return outputUri.toFilePath();
      }
    } catch (e) {
      debugPrint(
        'File picker save error: $e. Falling back to local documents.',
      );
    }

    // Fallback: write to documents directory
    final dir = await getApplicationDocumentsDirectory();
    final fallbackPath = '${dir.path}/$defaultFileName';
    final file = File(fallbackPath);
    await file.writeAsBytes(pdfBytes);
    return fallbackPath;
  }

  /// Prompts user to save Fountain file to desktop
  static Future<String?> saveFountainToFile(StoryProject project) async {
    final content = generateFountain(project);
    final bytes = Uint8List.fromList(utf8.encode(content));
    final defaultFileName = '${_sanitizeFileName(project.title)}.fountain';

    try {
      final outputUri = await FilePicker.saveFile(
        dialogTitle: 'Export Fountain Script (.fountain)',
        fileName: defaultFileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['fountain', 'txt'],
      );

      if (outputUri != null) {
        return outputUri.toFilePath();
      }
    } catch (e) {
      debugPrint('File picker save error: $e.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final fallbackPath = '${dir.path}/$defaultFileName';
    final file = File(fallbackPath);
    await file.writeAsBytes(bytes);
    return fallbackPath;
  }

  static bool _isCharacterCue(String line) {
    if (line.isEmpty || line.length > 32) return false;
    final upper = line.toUpperCase();
    if (upper != line) return false;
    // Common transitions or scene prefixes are not characters
    if (upper.startsWith('INT.') ||
        upper.startsWith('EXT.') ||
        upper.endsWith('TO:') ||
        upper.startsWith('FADE ')) {
      return false;
    }
    // Must contain letters
    return RegExp(r'^[A-Z0-9\s\.\(\)\-_]+$').hasMatch(line);
  }

  static Iterable<String> _scriptBodyLines(
    String scriptContent,
    String slugline,
  ) sync* {
    final lines = scriptContent.split('\n');
    final sluglineText = slugline.trim();
    var checkedFirstContentLine = false;

    for (final line in lines) {
      if (!checkedFirstContentLine && line.trim().isNotEmpty) {
        checkedFirstContentLine = true;
        if (sluglineText.isNotEmpty &&
            line.trim().toUpperCase() == sluglineText.toUpperCase()) {
          continue;
        }
      }
      yield line;
    }
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _sanitizeFileName(String title) {
    return title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_').toLowerCase();
  }
}
