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
import 'image.dart';

class Schematic {
  String? name;
  List<Image> images = [];
  Map<String, String> elements = {};

  Schematic();

  void toXml(XmlBuilder builder) {
    builder.element("schematic", nest:() {
      if (name != null) {
        builder.attribute("name", name);
      }

      for (var i in images) {
        i.toXml(builder);
      }

      for (var e in elements.keys) {
        builder.element("element", attributes: {"name": e, "description": elements[e] as String});
      }
    });
  }

  static Schematic parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'schematic') {
      print("Expected node with name 'schematic' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.childElements.isEmpty) {
      print("'schematic' metadata element is empty");
      throw OPAFParserException();
    }

    Schematic schematic = Schematic();
    schematic.name = node.getAttribute('name');

    for (var e in node.childElements) {
      if (e.localName == 'image') {
        schematic.images.add(Image.parse(e));
      }

      // Element
      if (e.localName == 'element') {
        var name = e.getAttribute('name');
        var description = e.getAttribute('description');

        if (name == null || description == null) {
          continue;
        }

        schematic.elements[name] = description;
      }
    }

    return schematic;
  }
}