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
import 'schematic_element.dart';

class Schematic {
  String? name;
  List<MetadataImage> images = [];
  List<SchematicElement> elements = [];

  Schematic();

  void toXml(XmlBuilder builder) {
    builder.element("schematic", nest:() {
      if (name != null) {
        builder.attribute("name", name);
      }

      for (var i in images) {
        i.toXml(builder);
      }

      for (var e in elements) {
        e.toXml(builder);
      }
    });
  }

  static Schematic parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'schematic') {
      throw OPAFParserException("Expected node with name 'schematic' and got '${node.name}'");
    }

    if (node.childElements.isEmpty) {
      throw OPAFParserException("'schematic' metadata element is empty");
    }

    Schematic schematic = Schematic();
    schematic.name = node.getAttribute('name');

    for (var e in node.childElements) {
      if (e.localName == 'image') {
        schematic.images.add(MetadataImage.parse(e));
      }

      // Element
      if (e.localName == 'element') {
        var name = e.getAttribute('name');
        var description = e.getAttribute('description');

        if (name == null || description == null) {
          continue;
        }

        schematic.elements.add(SchematicElement(name, description));
      }
    }

    return schematic;
  }
}