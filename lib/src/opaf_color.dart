/*
 * Copyright 2024 Scott Ware
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this library except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

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
  String description;

  OPAFColor(this.name, this.value, this.description);

  static bool isValid(String value) {
    if (hexColors.containsKey(value)) {
      return true;
    }

    return isHexColor(value);
  }

  static String toHex(String value) {
    if (!isValid(value)) {
      throw OPAFInvalidException("'$value' is not a valid hex rgb color string");
    }

    if (hexColors.containsKey(value)) {
      value = hexColors[value] as String;
    }

    return value.toLowerCase();
  }

  static OPAFColor parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (!node.name.local.contains('color')) {
      throw OPAFParserException("Expected node with name 'opaf:define_color' or 'color' and got '${node.name}'");
    }
  
    if (node.getAttribute('name') == null) {
      throw OPAFParserException("Name attribute not found for color");
    }

    if (node.getAttribute('value') == null) {
      throw OPAFParserException("Value for color not found");
    }

    String name = node.getAttribute("name") as String;
    String value = node.getAttribute("value") as String;
    value = toHex(value.trim().toLowerCase());
    String description = node.getAttribute("description") ?? "";
    
    return OPAFColor(name, value, description);
  }
}