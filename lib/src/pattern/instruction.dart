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

class PatternInstruction extends PatternElement {

  String? name;
  List<dynamic> elements;

  PatternInstruction(this.name, this.elements);

  void toXml(XmlBuilder builder) {
    builder.element("opaf:instruction", nest:() {
      if (name != null) {
        builder.attribute("name", name);
      }

      if (condition != null) {
        builder.attribute("condition", condition);
      }

      for (var e in elements) {
        e.toXml(builder);
      }
    });
  }

  PatternInstruction clone() {
    PatternInstruction newInstruction = PatternInstruction(
      name,
      []
    );

    newInstruction.condition = condition;

    for (var e in elements) {
      newInstruction.elements.add(e.clone());
    }

    return newInstruction;
  }

  static PatternInstruction parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'instruction') {
      throw OPAFParserException("Expected node with name 'opaf:instruction' and got '${node.name}'");
    }
  
    PatternInstruction instruction = PatternInstruction(null, []);
  
    if (node.getAttribute('name') != null) {
      instruction.name = node.getAttribute("name") as String;
    }

    if (node.getAttribute('condition') != null) {
      instruction.condition = node.getAttribute("condition") as String;
    }

    // Elements
    for (var n in node.childElements) {
      if (n.localName == 'action') {
        instruction.elements.add(PatternAction.parse(n));
      } else if (n.localName == "block") {
        instruction.elements.add(PatternBlock.parse(n));
      } else if (n.localName == "repeat") {
        instruction.elements.add(PatternRepeat.parse(n, instructionRepeat: true));
      } else {
        throw OPAFParserException("Instruction does not support '${n.localName}' nodes");
      }
    }

    return instruction;
  }
}