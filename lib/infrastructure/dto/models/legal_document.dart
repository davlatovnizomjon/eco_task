/// One numbered part of a legal text.
class LegalSection {
  /// Heading without its number; empty when the part has none.
  final String heading;

  /// Text under the heading.
  final String body;

  /// Builds a section.
  const LegalSection({required this.heading, required this.body});
}

/// A legal text (terms of use or privacy policy) as `GET legal/terms/` and `GET legal/privacy/` return it.
class LegalDocument {
  /// Title of the document.
  final String title;

  /// When the text was last changed on the backend, in the device's time zone.
  final DateTime updatedAt;

  /// The text split into numbered parts.
  final List<LegalSection> sections;

  /// Builds a document from its parts.
  const LegalDocument({required this.title, required this.updatedAt, required this.sections});

  /// Parses `{title, message, updated_at}`.
  factory LegalDocument.fromJson(Map<String, dynamic> json) => LegalDocument(
    title: '${json['title'] ?? ''}'.trim(),
    updatedAt: (DateTime.tryParse('${json['updated_at']}') ?? DateTime.now()).toLocal(),
    sections: parseSections('${json['message'] ?? ''}'),
  );

  /// Splits [message] into sections: parts are separated by a blank line, the first line of a part is its heading
  /// (a leading `1.` is dropped because the sheet numbers the parts itself) and the rest is its text. A part of a single
  /// line is text without a heading.
  static List<LegalSection> parseSections(String message) {
    final sections = <LegalSection>[];
    for (final part in message.trim().split(RegExp(r'\n\s*\n'))) {
      final lines = part.trim().split('\n');
      if (lines.first.trim().isEmpty) continue;
      if (lines.length == 1) {
        sections.add(LegalSection(heading: '', body: lines.first.trim()));
      } else {
        sections.add(
          LegalSection(
            heading: lines.first.replaceFirst(RegExp(r'^\s*\d+[.)]\s*'), '').trim(),
            body: lines.skip(1).join('\n').trim(),
          ),
        );
      }
    }
    return sections;
  }
}
