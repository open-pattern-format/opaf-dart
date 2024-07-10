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

import 'package:opaf/src/pattern/action.dart';
import 'package:xml/xml.dart';

import '../opaf_exceptions.dart';
import 'block.dart';
import 'element.dart';
import 'repeat.dart';

class ChartRow extends PatternElement {

  String type;
  List<dynamic> elements;

  ChartRow(this.type, this.elements);

  void toXml(XmlBuilder builder) {
    builder.element("opaf:row", nest:() {
      builder.attribute("type", type);

      if (condition != null) {
        builder.attribute("condition", condition);
      }

      for (var e in elements) {
        e.toXml(builder);
      }
    });
  }

  static ChartRow parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'row') {
      print("Expected node with name 'opaf:row' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.getAttribute('type') == null) {
      print("Attribute 'type' missing from row element");
      throw OPAFParserException();
    }

    String type = node.getAttribute('type') as String;

    if (!['ws','rs','round'].any((t) => type == t)) {
      print("Attribute 'type' must be one of 'rs, ws, round' for row element");
      throw OPAFParserException();
    }
  
    ChartRow row = ChartRow(type, []);

    if (node.getAttribute('condition') != null) {
      row.condition = node.getAttribute("condition") as String;
    }

    // Elements
    for (var n in node.childElements) {
      if (n.localName == 'action') {
        row.elements.add(PatternAction.parse(n));
      } else if (n.localName == "block") {
        row.elements.add(PatternBlock.parse(n));
      } else if (n.localName == "repeat") {
        row.elements.add(PatternRepeat.parse(n, chartRepeat: true));
      } else {
        print("Row does not support '${n.localName}' nodes");
        throw OPAFParserException();
      }
    }

    return row;
  }
}