import 'package:xml/xml.dart';

import '../opaf_exceptions.dart';
import 'image.dart';

class Schematic {
  String? name;
  List<Image> images = [];
  Map<String, String> elements = {};

  Schematic();

  void toXml(XmlBuilder builder) {
    builder.element("schematic", nest:() {
      if (name != null) {
        builder.attribute("name", name);
      }

      for (var i in images) {
        i.toXml(builder);
      }

      for (var e in elements.keys) {
        builder.element("element", attributes: {"name": e, "description": elements[e] as String});
      }
    });
  }

  static Schematic parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'schematic') {
      print("Expected node with name 'schematic' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.childElements.isEmpty) {
      print("'schematic' metadata element is empty");
      throw OPAFParserException();
    }

    Schematic schematic = Schematic();
    schematic.name = node.getAttribute('name');

    for (var e in node.childElements) {
      if (e.localName == 'image') {
        schematic.images.add(Image.parse(e));
      }

      // Element
      if (e.localName == 'element') {
        var name = e.getAttribute('name');
        var description = e.getAttribute('description');

        if (name == null || description == null) {
          continue;
        }

        schematic.elements[name] = description;
      }
    }

    return schematic;
  }
}