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
import 'element.dart';

class PatternImage extends PatternElement {
  String name;
  String? caption;

  PatternImage(this.name);

  void toXml(XmlBuilder builder) {
    builder.element("opaf:image", nest:() {
      builder.attribute("name", name);

      if (caption != null) {
        builder.attribute("caption", caption);
      }

      if (condition != null) {
        builder.attribute("condition", condition);
      }
    });
  }

  static PatternImage parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'image') {
      throw OPAFParserException("Expected node with name 'opaf:image' and got '${node.name}'");
    }

    if (node.getAttribute('name') == null) {
      throw OPAFParserException("Attribute 'name' missing from image element");
    }

    PatternImage image = PatternImage(node.getAttribute('name') as String);

    if (node.getAttribute('caption') != null) {
      image.caption = node.getAttribute('caption');
    }

    if (node.getAttribute('condition') != null) {
      image.condition = node.getAttribute('condition');
    }

    return image;
  }
}