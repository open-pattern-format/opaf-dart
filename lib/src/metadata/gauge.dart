import 'package:xml/xml.dart';

import '../opaf_exceptions.dart';

class Gauge {

  static final supportedUnits = [
      'cm',
      'mm',
      'in',
  ];

  String units;
  int width;
  int? height;
  int stitches;
  int? rows;
  String? description;

  Gauge(this.units, this.width, this.stitches);

  void toXml(XmlBuilder builder) {
    builder.element("gauge", nest:() {
      builder.attribute("units", units);
      builder.attribute("width", width.toString());

      if (height != null) {
        builder.attribute("height", height.toString());
      }

      builder.attribute("stitches", stitches.toString());

      if (rows != null) {
        builder.attribute("rows", rows.toString());
      }

      if (description != null) {
        builder.attribute("description", description);
      }
    });
  }

  static Gauge parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'gauge') {
      print("Expected node with name 'gauge' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.getAttribute('units') == null) {
      print("Attribute 'unit' missing from 'gauge' element");
      throw OPAFParserException();
    }

    if (node.getAttribute('width') == null) {
      print("Attribute 'width' missing from 'gauge' element");
      throw OPAFParserException();
    }

    if (node.getAttribute('stitches') == null) {
      print("Attribute 'stitches' missing from 'stitches' element");
      throw OPAFParserException();
    }

    String units = node.getAttribute('units') as String;

    if (!supportedUnits.contains(units)) {
      print("Gauge unit '$units' is not supported");
      throw OPAFParserException();
    }

    int? width = int.tryParse(node.getAttribute('width') as String);
    int? stitches = int.tryParse(node.getAttribute('stitches') as String);

    if (width == null) {
      print("Gauge attribute 'width' is not valid");
      throw OPAFParserException();
    }

    if (stitches == null) {
      print("Gauge attribute 'stitches' is not valid");
      throw OPAFParserException();
    }

    Gauge gauge = Gauge(units, width, stitches);

    if (node.getAttribute('height') != null) {
      gauge.height = int.tryParse(node.getAttribute('height') as String);
    }
    
    if (node.getAttribute('rows') != null) {
      gauge.rows = int.tryParse(node.getAttribute('rows') as String);
    }

    gauge.description = node.getAttribute('description');

    return gauge;
  }
}