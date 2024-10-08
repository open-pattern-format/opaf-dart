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
import 'opaf_exceptions.dart';



class OPAFConfig {
  String name;
  String value;
  bool required;
  List<String> allowedValues;
  String? title;
  String? description;

  OPAFConfig(
    this.name, 
    this.value,
    this.required,
    this.allowedValues,
    this.title,
    this.description,
  );

  static OPAFConfig parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'define_config') {
      throw OPAFParserException("Expected node with name 'opaf:define_config' and got '${node.name}'");
    }
  
    if (node.getAttribute('name') == null) {
      throw OPAFParserException("Name attribute not found for value");
    }
  
    String name = node.getAttribute("name") as String;
    String value = node.getAttribute("value") ?? '';
  
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

    // Title
    String? title = node.getAttribute("title");

    // Description
    String? description = node.getAttribute("description");
    
    return OPAFConfig(name, value, required, allowedValues, title, description);
  }
}