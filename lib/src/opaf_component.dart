import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import 'opaf_exceptions.dart';
import 'opaf_utils.dart';

class OPAFComponent {

  String name;
  String uniqueId;
  List<String> elements;
  String? condition;

  OPAFComponent(this.name, this.uniqueId, this.elements, this.condition);

  static OPAFComponent parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'component') {
      print("Expected node with name 'opaf:component' and got '${node.name}'");
      throw OPAFParserException();
    }
  
    if (node.getAttribute('name') == null) {
      print("Name attribute not found for component");
      throw OPAFParserException();
    }
  
    // Check node
    OPAFUtils.checkNode(node, []);
    
    String name = node.getAttribute("name") as String;
    String uniqueId = node.getAttribute("unique_id") ?? Uuid().v4();
    
    // Elements
    List<String> elements = [];
    for (var e in node.childElements) {
      elements.add(e.toXmlString());
    }

    if (elements.isEmpty) {
      print("Component with name '$name' is empty or contains no valid elements");
      throw OPAFParserException();
    }

    // Condition
    String? condition = node.getAttribute('condition');

    return OPAFComponent(name, uniqueId, elements, condition);
  }
}