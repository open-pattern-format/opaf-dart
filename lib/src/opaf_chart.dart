import 'package:xml/xml.dart';

import 'opaf_exceptions.dart';
import 'opaf_utils.dart';

class OPAFChart {

  static final chartNodes = [
    'action',
    'row',
  ];

  String name;
  List<String> rows;

  OPAFChart(this.name, this.rows);

  static OPAFChart parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (!node.name.local.contains('chart')) {
      print("Expected node with name 'opaf:define_chart' or 'chart' and got '${node.name}'");
      throw OPAFParserException();
    }
  
    if (node.getAttribute('name') == null) {
      print("Name attribute not found for chart");
      throw OPAFParserException();
    }
  
    // Check node
    OPAFUtils.checkNode(node, chartNodes);
    
    String name = node.getAttribute("name") as String;
    
    // Rows
    List<String> rows = [];
    for (var e in node.childElements) {
      rows.add(e.toXmlString());
    }

    if (rows.isEmpty) {
      print("Chart with name '$name' is empty or contains no valid rows");
      throw OPAFParserException();
    }

    return OPAFChart(name, rows);
  }
}