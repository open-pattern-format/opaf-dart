import 'package:xml/xml.dart';

import '../opaf_exceptions.dart';

class Yarn {
  String name;
  String? brand;
  String? weight;
  int? unitWeight;
  int? length;

  Yarn(this.name);

  void toXml(XmlBuilder builder) {
    builder.element("yarn", nest:() {
      builder.attribute("name", name);

      if (brand != null) {
        builder.attribute("brand", brand);
      }

      if (weight != null) {
        builder.attribute("weight", weight);
      }

      if (unitWeight != null) {
        builder.attribute("unit_weight", unitWeight.toString());
      }
  
      if (length != null) {
        builder.attribute("length", length.toString());
      }
    });
  }

  static Yarn parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'yarn') {
      print("Expected node with name 'yarn' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.getAttribute('name') == null) {
      print("Attribute 'name' missing from 'yarn' element");
      throw OPAFParserException();
    }

    String name = node.getAttribute('name') as String;

    Yarn yarn = Yarn(name);
    yarn.brand = node.getAttribute('brand');
    yarn.weight = node.getAttribute('weight');

    if (node.getAttribute('unit_weight') != null) {
      yarn.unitWeight = int.tryParse(node.getAttribute('unit_weight') as String);
    }

    if (node.getAttribute('length') != null) {
      yarn.length = int.tryParse(node.getAttribute('length') as String);
    }

    return yarn;
  }
}