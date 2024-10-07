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
import 'image.dart';
import 'instruction.dart';
import 'text.dart';

class PatternRepeat extends PatternElement {

  String? title;
  String count;
  List<dynamic> elements;

  PatternRepeat(this.count, this.elements);

  void toXml(XmlBuilder builder) {
    builder.element("opaf:repeat", nest:() {
      builder.attribute("count", count);

      if (title != null) {
        builder.attribute("title", title);
      }

      if (condition != null) {
        builder.attribute("condition", condition);
      }

      for (var e in elements) {
        e.toXml(builder);
      }
    });
  }

  PatternRepeat clone() {
    PatternRepeat newRepeat = PatternRepeat(
      count,
      []
    );

    newRepeat.title = title;
    newRepeat.condition = condition;

    for (var e in elements) {
      newRepeat.elements.add(e.clone());
    }

    return newRepeat;
  }

  static PatternRepeat parse(XmlElement node, {bool instructionRepeat=false, bool chartRepeat=false}) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'repeat') {
      throw OPAFParserException("Expected node with name 'opaf:repeat' and got '${node.name}'");
    }

    if (node.getAttribute('count') == null) {
      throw OPAFParserException("Attribute 'count' missing from repeat element");
    }
  
    PatternRepeat repeat = PatternRepeat(node.getAttribute("count") as String, []);

    if (node.getAttribute('title') != null) {
      repeat.title = node.getAttribute("title") as String;
    }

    if (node.getAttribute('condition') != null) {
      repeat.condition = node.getAttribute("condition") as String;
    }

    // Elements
    for (var n in node.childElements) {
      if (instructionRepeat) {
        if (n.localName == "action") {
          repeat.elements.add(PatternAction.parse(n));
        } else if (n.localName == "block") {
          repeat.elements.add(PatternBlock.parse(n));
        } else if (n.localName == "repeat") {
          repeat.elements.add(PatternRepeat.parse(n, instructionRepeat: true));
        } else {
          throw OPAFParserException("Instruction repeat does not support '${n.localName}' nodes");
        }
      } else if (chartRepeat) {
        if (n.localName == "action") {
          repeat.elements.add(PatternAction.parse(n));
        } else {
          throw OPAFParserException("Chart repeat does not support '${n.localName}' nodes");
        }
      } else {
        if (n.localName == 'instruction') {
          repeat.elements.add(PatternInstruction.parse(n));
        } else if (n.localName == "text") {
          repeat.elements.add(PatternText.parse(n));
        } else if (n.localName == "repeat") {
          repeat.elements.add(PatternRepeat.parse(n));
        } else if (n.localName == "block") {
          repeat.elements.add(PatternBlock.parse(n));
        } else if (n.localName == "image") {
          repeat.elements.add(PatternImage.parse(n));
        } else if (n.localName == "action") {
          repeat.elements.add(PatternAction.parse(n));
        } else {
          throw OPAFParserException("Repeat does not support '${n.localName}' nodes");
        }
      }
    }

    return repeat;
  }
}