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

class PatternAction extends PatternElement {

  String name;
  Map<String, dynamic> params;

  PatternAction(this.name, this.params);

  @override
  void toXml(XmlBuilder builder, {bool actionDefinition = false}) {
    builder.element(actionDefinition ? "action" : "opaf:action", nest:() {
      builder.attribute("name", name);

      for (var p in params.keys) {
        builder.attribute(p, params[p]);
      }

      if (condition != null) {
        builder.attribute("condition", condition);
      }
    });
  }

  static PatternAction parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'action') {
      print("Expected node with name 'opaf:action' or 'action' and got '${node.name}'");
      throw OPAFParserException();
    }
  
    if (node.getAttribute('name') == null) {
      print("Name attribute not found for action");
      throw OPAFParserException();
    }

    PatternAction action = PatternAction(
      node.getAttribute("name") as String,
      {},
    );

    // Attributes
    for (var a in node.attributes) {
      if (a.localName == 'name') {
        continue;
      } else if (a.localName == 'condition') {
        action.condition = a.value;
      } else {
        action.params[a.localName] = a.value;
      }
    }

    return action;
  }
}