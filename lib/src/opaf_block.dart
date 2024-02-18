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

class OPAFBlock {

  String name;
  Map<String, dynamic> params;
  List<String> elements;

  OPAFBlock(this.name, this.params, this.elements);

  static OPAFBlock parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'define_block') {
      print("Expected node with name 'opaf:define_block' and got '${node.name}'");
      throw OPAFParserException();
    }
  
    if (node.getAttribute('name') == null) {
      print("Name attribute not found for block");
      throw OPAFParserException();
    }
  
    // Check node
    OPAFUtils.checkNode(node, []);
    
    String name = node.getAttribute("name") as String;

    // Params
    Map<String, dynamic> params = {};
    if (node.getAttribute('params') != null) {
      String paramsAttr = node.getAttribute('params') as String;

      for (var param in paramsAttr.split(" ")) {
          if (param.contains('=')) {
              var paramList = param.split('=');
              params[paramList[0]] = OPAFUtils.strToNum(paramList[1]);
          } else {
              params[param] = '';
          }
      }
    }
    
    // Elements
    List<String> elements = [];
    for (var e in node.childElements) {
      elements.add(e.toXmlString());
    }

    if (elements.isEmpty) {
      print("Block with name '$name' is empty or contains no valid elements");
      throw OPAFParserException();
    }

    return OPAFBlock(name, params, elements);
  }
}