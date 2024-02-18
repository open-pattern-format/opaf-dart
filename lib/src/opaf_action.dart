import 'package:xml/xml.dart';

import 'opaf_exceptions.dart';
import 'opaf_utils.dart';

class OPAFAction {

  String name;
  Map<String, dynamic> params;
  List<String> elements;

  OPAFAction(this.name, this.params, this.elements);

  static OPAFAction parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'define_action') {
      print("Expected node with name 'opaf:define_action' and got '${node.name}'");
      throw OPAFParserException();
    }
  
    if (node.getAttribute('name') == null) {
      print("Name attribute not found for action");
      throw OPAFParserException();
    }
    
    String name = node.getAttribute("name") as String;

    // Params
    Map<String, dynamic> params = {};
    if (node.getAttribute('params') != null) {
      String paramsAttr = node.getAttribute('params') as String;

      for (var param in paramsAttr.split(" ")) {
          if (param.contains('=')) {
              var paramList = param.split('=');
              params[paramList[0]] = OPAFUtils.strToNum(paramList[1]);
          } else {
              params[param] = '';
          }
      }
    }
    
    // Elements
    List<String> elements = [];
    for (var e in node.childElements) {
      if (e.name.local == 'action') {
        elements.add(e.toXmlString());
      }
    }

    if (elements.isEmpty) {
      print("No actions found for action '$name'");
      throw OPAFParserException();
    }

    return OPAFAction(name, params, elements);
  }
}