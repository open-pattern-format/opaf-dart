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

class PatternBlock extends PatternElement {

  String name;
  Map<String, dynamic> params;

  PatternBlock(this.name, this.params);

  @override
  void toXml(XmlBuilder builder) {
    builder.element("opaf:block", nest:() {
      builder.attribute("name", name);

      for (var p in params.keys) {
        builder.attribute(p, params[p]);
      }

      if (condition != null) {
        builder.attribute("condition", condition);
      }
    });
  }

  PatternBlock clone() {
    PatternBlock newBlock = PatternBlock(
      name,
      Map.from(params)
    );

    newBlock.condition = condition;

    return newBlock;
  }

  static PatternBlock parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'block') {
      throw OPAFParserException("Expected node with name 'opaf:block' and got '${node.name}'");
    }
  
    if (node.getAttribute('name') == null) {
      throw OPAFParserException("Name attribute not found for block");
    }

    PatternBlock block = PatternBlock(
      node.getAttribute("name") as String,
      {},
    );

    // Attributes
    for (var a in node.attributes) {
      if (a.localName == 'name') {
        continue;
      } else if (a.localName == 'condition') {
        block.condition = a.value;
      } else {
        block.params[a.localName] = a.value;
      }
    }

    return block;
  }
}