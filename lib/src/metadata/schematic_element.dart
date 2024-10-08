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

import '../opaf_exceptions.dart';

class SchematicElement {

  String name;
  String description;

  SchematicElement(this.name, this.description);

  void toXml(XmlBuilder builder) {
    builder.element("element", nest:() {
      builder.attribute("name", name);
      builder.attribute("description", description);
    });
  }

  static parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'element') {
      throw OPAFParserException("Expected node with name 'element' and got '${node.name}'");
    }

    if (node.getAttribute('name') == null) {
      throw OPAFParserException("Attribute 'name' missing from schematic element");
    }

    if (node.getAttribute('description') == null) {
      throw OPAFParserException("Attribute 'description' missing from schematic element");
    }

    SchematicElement element = SchematicElement(
      node.getAttribute('name') as String,
      node.getAttribute('description') as String
    );

    return element;
  }
}