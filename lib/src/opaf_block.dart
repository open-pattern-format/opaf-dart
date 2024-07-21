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
import 'package:opaf/src/pattern/instruction.dart';
import 'package:xml/xml.dart';

import 'opaf_exceptions.dart';
import 'opaf_utils.dart';
import 'pattern/action.dart';
import 'pattern/block.dart';
import 'pattern/repeat.dart';
import 'pattern/text.dart';

class OPAFBlock {

  String name;
  Map<String, dynamic> params;
  List<dynamic> elements;

  OPAFBlock(this.name, this.params, this.elements);

  static OPAFBlock parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'define_block') {
      throw OPAFParserException("Expected node with name 'opaf:define_block' and got '${node.name}'");
    }
  
    if (node.getAttribute('name') == null) {
      throw OPAFParserException("Name attribute not found for block");
    }
  
    // Check node
    OPAFUtils.checkNode(node, []);

    OPAFBlock block = OPAFBlock(
      node.getAttribute("name") as String,
      {},
      [],
    );
    
    // Params
    if (node.getAttribute('params') != null) {
      String paramsAttr = node.getAttribute('params') as String;

      for (var param in paramsAttr.split(" ")) {
          if (param.contains('=')) {
              var paramList = param.split('=');
              block.params[paramList[0]] = OPAFUtils.strToNum(paramList[1]);
          } else {
              block.params[param] = '';
          }
      }
    }
    
    // Elements
    for (var n in node.childElements) {
      if (n.localName == 'instruction') {
        block.elements.add(PatternInstruction.parse(n));
      } else if (n.localName == "text") {
        block.elements.add(PatternText.parse(n));
      } else if (n.localName == "repeat") {
        block.elements.add(PatternRepeat.parse(n));
      } else if (n.localName == "block") {
        block.elements.add(PatternBlock.parse(n));
      } else if (n.localName == "image") {
        block.elements.add(PatternImage.parse(n));
      } else if (n.localName == "action") {
        block.elements.add(PatternAction.parse(n));
      } else {
        throw OPAFParserException("Block does not support '${n.localName}' nodes");
      }
    }

    if (block.elements.isEmpty) {
      throw OPAFParserException("Block with name '${block.name}' is empty or contains no valid elements");
    }

    return block;
  }
}