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

import 'opaf_exceptions.dart';
import 'opaf_utils.dart';
import 'pattern/action.dart';

class OPAFAction {

  String name;
  Map<String, dynamic> params;
  List<PatternAction> elements;
  bool custom = false;

  OPAFAction(this.name, this.params, this.elements);

  static OPAFAction parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'define_action') {
      throw OPAFParserException("Expected node with name 'opaf:define_action' and got '${node.name}'");
    }
  
    if (node.getAttribute('name') == null) {
      throw OPAFParserException("Name attribute not found for action");
    }

    OPAFAction action = OPAFAction(
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
              action.params[paramList[0]] = OPAFUtils.strToNum(paramList[1]);
          } else {
              action.params[param] = '';
          }
      }
    }
    
    // Elements
    for (var e in node.childElements) {
      if (e.name.local == 'action') {
        action.elements.add(PatternAction.parse(e));
      }
    }

    if (action.elements.isEmpty) {
      throw OPAFParserException("No actions found for action '${action.name}'");
    }

    if (node.getAttribute('custom') != null) {
      action.custom = bool.parse(node.getAttribute('custom') as String, caseSensitive: false);
    }

    return action;
  }
}