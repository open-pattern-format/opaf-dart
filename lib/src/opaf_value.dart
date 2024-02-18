import 'package:xml/xml.dart';

import 'opaf_exceptions.dart';



class OPAFValue {
  String name;
  String value;
  bool config;
  bool required;
  List<String> allowedValues;
  String? description;
  String? condition;

  OPAFValue(
    this.name, 
    this.value,
    this.config,
    this.required,
    this.allowedValues,
    this.description,
    this.condition
  );

  static OPAFValue parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'define_value') {
      print("Expected node with name 'opaf:define_value' and got '${node.name}'");
      throw OPAFParserException();
    }
  
    if (node.getAttribute('name') == null) {
      print("Name attribute not found for value");
      throw OPAFParserException();
    }

    if (node.getAttribute('value') == null) {
      print("Value not defined");
      throw OPAFParserException();
    }
  
    String name = node.getAttribute("name") as String;
    String value = node.getAttribute("value") as String;
  
    // Configurable
    bool config = false;
    if (node.getAttribute('config') != null) {
      config = bool.parse(node.getAttribute('config') as String, caseSensitive: false);
    }
  
      // Required
    bool required = false;
    if (node.getAttribute('required') != null) {
      required = bool.parse(node.getAttribute('required') as String, caseSensitive: false);
    }

    // Allowed Values
    List<String> allowedValues = [];
    if (node.getAttribute('allowed_values') != null) {
        allowedValues = (node.getAttribute('allowed_values') as String).split(',');
        allowedValues.map((v) => v.trim());
    }

    // Description
    String? description = node.getAttribute("description");

    // Condition
    String? condition = node.getAttribute('condition');
    
    return OPAFValue(name, value, config, required, allowedValues, description, condition);
  }
}