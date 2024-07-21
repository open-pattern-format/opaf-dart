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

import 'package:opaf/src/pattern/image.dart';
import 'package:uuid/data.dart';
import 'package:uuid/rng.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import 'opaf_exceptions.dart';
import 'opaf_utils.dart';
import 'pattern/block.dart';
import 'pattern/instruction.dart';
import 'pattern/repeat.dart';
import 'pattern/text.dart';

class OPAFComponent {

  String name;
  String uniqueId;
  List<dynamic> elements;
  String? condition;

  OPAFComponent(this.name, this.uniqueId, this.elements, this.condition);

  static OPAFComponent parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'component') {
      throw OPAFParserException("Expected node with name 'opaf:component' and got '${node.name}'");
    }
  
    if (node.getAttribute('name') == null) {
      throw OPAFParserException("Name attribute not found for component");
    }
  
    // Check node
    OPAFUtils.checkNode(node, []);

    OPAFComponent component = OPAFComponent(
      node.getAttribute("name") as String,
      node.getAttribute("unique_id") ?? Uuid(goptions: GlobalOptions(CryptoRNG())).v4(),
      [],
      node.getAttribute('condition'),
    );
    
    // Elements
    for (var n in node.childElements) {
      if (n.localName == 'instruction') {
        component.elements.add(PatternInstruction.parse(n));
      } else if (n.localName == "text") {
        component.elements.add(PatternText.parse(n));
      } else if (n.localName == "repeat") {
        component.elements.add(PatternRepeat.parse(n));
      } else if (n.localName == "block") {
        component.elements.add(PatternBlock.parse(n));
      } else if (n.localName == "image") {
        component.elements.add(PatternImage.parse(n));
      } else {
        throw OPAFParserException("Component does not support '${n.localName}' nodes");
      }
    }

    if (component.elements.isEmpty) {
      throw OPAFParserException("Component with name '$component.name' is empty or contains no valid elements");
    }

    return component;
  }
}