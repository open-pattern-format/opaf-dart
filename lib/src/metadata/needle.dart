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

class Needle {

  String type;
  String size;

  Needle(this.type, this.size);

  void toXml(XmlBuilder builder) {
    builder.element("notion", nest:() {
      builder.attribute("type", type);
      builder.attribute("size", size);
    });
  }

  static parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'needle') {
      throw OPAFParserException("Expected node with name 'needle' and got '${node.name}'");
    }

    if (node.getAttribute('type') == null) {
      throw OPAFParserException("Attribute 'type' missing from 'needle' element");
    }

    if (node.getAttribute('size') == null) {
      throw OPAFParserException("Attribute 'size' missing from 'needle' element");
    }

    Needle needle = Needle(
      node.getAttribute('type') as String,
      node.getAttribute('size') as String,
    );

    return needle;
  }
}