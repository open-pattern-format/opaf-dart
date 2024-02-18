import 'package:xml/xml.dart';

import '../opaf_exceptions.dart';

class Image {
  String name;
  String? tag;
  String? caption;

  Image(this.name);

  void toXml(XmlBuilder builder) {
    builder.element("image", nest:() {
      builder.attribute("name", name);

      if (tag != null) {
        builder.attribute("tag", tag);
      }

      if (caption != null) {
        builder.attribute("caption", caption);
      }
    });
  }

  static Image parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'image') {
      print("Expected node with name 'image' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.getAttribute('name') == null) {
      print("Attribute 'name' missing from image element");
      throw OPAFParserException();
    }

    String name = node.getAttribute('name') as String;

    Image image = Image(name);

    if (node.getAttribute('tag') != null) {
      image.tag = node.getAttribute('tag');
    }

    if (node.getAttribute('caption') != null) {
      image.caption = node.getAttribute('caption');
    }

    return image;
  }
}