import 'package:string_validator/string_validator.dart';
import 'package:xml/xml.dart';

import '../opaf_exceptions.dart';

class Technique {
  String name;
  String? description;
  String? url;

  Technique(this.name);

  void toXml(XmlBuilder builder) {
    builder.element("technique", nest:() {
      builder.attribute("name", name);

      if (description != null) {
        builder.attribute("description", description);
      }

      if (url != null) {
        builder.attribute("url", url);
      }
    });
  }

  static Technique parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'technique') {
      print("Expected node with name 'technique' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.getAttribute('name') == null) {
      print("Attribute 'name' missing from technique element");
      throw OPAFParserException();
    }

    String name = node.getAttribute('name') as String;

    Technique technique = Technique(name);
    technique.description = node.getAttribute('description');

    if (node.getAttribute('url') != null) {
      String url = node.getAttribute('url') as String;

      if (isURL(url)) {
        technique.url = url;
      }
    }

    return technique;
  }
}