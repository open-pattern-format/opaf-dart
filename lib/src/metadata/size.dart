import 'package:xml/xml.dart';

import '../opaf_exceptions.dart';
import 'measurement.dart';

class Size {
  String name;
  String? description;
  List<Measurement> measurements = [];

  Size(this.name);

  void toXml(XmlBuilder builder) {
    builder.element("size", nest:() {
      builder.attribute("name", name);

      if (description != null) {
        builder.attribute("description", description);
      }

      for (var m in measurements) {
        m.toXml(builder);
      }
    });
  }

  static Size parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'size') {
      print("Expected node with name 'size' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.getAttribute('name') == null) {
      print("Attribute 'name' missing from size element");
      throw OPAFParserException();
    }

    String name = node.getAttribute('name') as String;

    Size size = Size(name);
    size.description = node.getAttribute('description');

    for (var e in node.childElements) {
      if (e.name.local == 'measurement') {
        size.measurements.add(Measurement.parse(e));
      }
    }

    return size;
  }
}