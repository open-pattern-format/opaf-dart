import 'package:xml/xml.dart';

import '../opaf_exceptions.dart';

class Note {
  String text;
  String? tag;

  Note(this.text);

  void toXml(XmlBuilder builder) {
    builder.element("note", nest:() {
      builder.attribute("text", text);

      if (tag != null) {
        builder.attribute("tag", tag);
      }
    });
  }

  static Note parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'note') {
      print("Expected node with name 'note' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.getAttribute('text') == null) {
      print("Attribute 'text' missing from 'note' element");
      throw OPAFParserException();
    }

    String text = node.getAttribute('text') as String;

    Note note = Note(text);
    note.tag = node.getAttribute('tag');

    return note;
  }
}