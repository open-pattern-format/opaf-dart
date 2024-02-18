import 'package:xml/xml.dart';

import '../opaf_exceptions.dart';
import '../opaf_metadata.dart';
import 'note.dart';

class MetadataUtils {

  static final supportedNodes = [
      'color',
      'copyright',
      'description',
      'designer',
      'element',
      'gauge',
      'image',
      'link',
      'measurement',
      'needles',
      'note',
      'notion',
      'published',
      'title',
      'schematic',
      'size',
      'table',
      'tag',
      'technique',
      'yarn'
  ];

  static final textNodes = [
      'copyright',
      'description',
      'published',
      'tag',
      'title'
  ];

  static XmlNode checkNode(XmlElement node) {
    if (node.childElements.isEmpty) {
        return node;
    }

    for (var child in node.childElements) {
      if (child.nodeType != XmlNodeType.ELEMENT) {
          child.remove();
          continue;
      }

      if (!supportedNodes.contains(child.name.local)) {
          print("Node with name '${child.name.local}' not recognized");
          throw OPAFParserException();
      }

      if (textNodes.contains(child.name.local)) {
          continue;
      }

      if (child.childElements.isNotEmpty) {
          checkNode(child);
      }
    }

    return node;
  }

  static List<Note> getNotesByTag(OPAFMetadata metadata, String tag) {
    List<Note> notes = [];

    for (var n in metadata.notes) {
      if (n.tag == null) {
        if (tag.isEmpty) {
          notes.add(n);
        } else {
          continue;
        }
      }

      if (n.tag == tag) {
        notes.add(n);
      }
    }

    return notes;
  }
}