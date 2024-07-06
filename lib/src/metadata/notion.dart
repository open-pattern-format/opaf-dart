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

class Notion {

  String name;
  String? description;

  Notion(this.name);

  void toXml(XmlBuilder builder) {
    builder.element("notion", nest:() {
      builder.attribute("name", name);

      if (description != null) {
        builder.attribute("description", description);
      }
    });
  }

  static parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'notion') {
      print("Expected node with name 'notion' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.getAttribute('name') == null) {
      print("Attribute 'name' missing from 'notion' element");
      throw OPAFParserException();
    }

    Notion notion = Notion(node.getAttribute('name') as String);
    
    if (node.getAttribute('description') != null) {
      notion.description = node.getAttribute('description') as String;
    }

    return notion;
  }
}