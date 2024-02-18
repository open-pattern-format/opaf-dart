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
import 'measurement.dart';

class Size {
  String name;
  String? description;
  List<Measurement> measurements = [];

  Size(this.name);

  void toXml(XmlBuilder builder) {
    builder.element("size", nest:() {
      builder.attribute("name", name);

      if (description != null) {
        builder.attribute("description", description);
      }

      for (var m in measurements) {
        m.toXml(builder);
      }
    });
  }

  static Size parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'size') {
      print("Expected node with name 'size' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.getAttribute('name') == null) {
      print("Attribute 'name' missing from size element");
      throw OPAFParserException();
    }

    String name = node.getAttribute('name') as String;

    Size size = Size(name);
    size.description = node.getAttribute('description');

    for (var e in node.childElements) {
      if (e.name.local == 'measurement') {
        size.measurements.add(Measurement.parse(e));
      }
    }

    return size;
  }
}