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

class Image {
  String name;
  String? tag;

  Image(this.name);

  void toXml(XmlBuilder builder) {
    builder.element("image", nest:() {
      builder.attribute("name", name);

      if (tag != null) {
        builder.attribute("tag", tag);
      }

    });
  }

  static Image parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'image') {
      print("Expected node with name 'image' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.getAttribute('name') == null) {
      print("Attribute 'name' missing from image element");
      throw OPAFParserException();
    }

    String name = node.getAttribute('name') as String;

    Image image = Image(name);

    if (node.getAttribute('tag') != null) {
      image.tag = node.getAttribute('tag');
    }

    return image;
  }
}