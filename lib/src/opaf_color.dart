import 'package:xml/xml.dart';
import 'package:string_validator/string_validator.dart';

import 'opaf_exceptions.dart';

class OPAFColor {

  static final hexColors = {
    'black': '#000000',
    'silver': '#C0C0C0',
    'white': '#FFFFFF',
    'red': '#FF0000',
    'purple': '#800080',
    'green': '#008000',
    'yellow': '#FFFF00',
    'blue': '#0000FF',
  };

  String name;
  String value;

  OPAFColor(this.name, this.value);

  static bool isValid(String value) {
    if (hexColors.containsKey(value)) {
      return true;
    }

    return isHexColor(value);
  }

  static String toHex(String value) {
    if (!isValid(value)) {
      print("'$value' is not a valid hex rgb color string");
      throw OPAFInvalidException();
    }

    if (hexColors.containsKey(value)) {
      value = hexColors[value] as String;
    }

    return value.toLowerCase();
  }

  static OPAFColor parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (!node.name.local.contains('color')) {
      print("Expected node with name 'opaf:define_color' or 'color' and got '${node.name}'");
      throw OPAFParserException();
    }
  
    if (node.getAttribute('name') == null) {
      print("Name attribute not found for color");
      throw OPAFParserException();
    }

    if (node.getAttribute('value') == null) {
      print("Value for color not found");
      throw OPAFParserException();
    }
    
    String name = node.getAttribute("name") as String;
    String value = node.getAttribute("value") as String;
    value = toHex(value.trim().toLowerCase());
    
    return OPAFColor(name, value);
  }
}