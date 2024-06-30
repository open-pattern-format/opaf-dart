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

import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import 'opaf_exceptions.dart';



class OPAFValue {
  String uniqueId;
  String name;
  String value;
  String? condition;

  OPAFValue(
    this.uniqueId,
    this.name, 
    this.value,
    this.condition
  );

  static OPAFValue parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'define_value') {
      print("Expected node with name 'opaf:define_value' and got '${node.name}'");
      throw OPAFParserException();
    }
  
    if (node.getAttribute('name') == null) {
      print("Name attribute not found for value");
      throw OPAFParserException();
    }

    if (node.getAttribute('value') == null) {
      print("Value not defined");
      throw OPAFParserException();
    }
  
    String uniqueId = node.getAttribute("unique_id") ?? Uuid().v4();
    String name = node.getAttribute("name") as String;
    String value = node.getAttribute("value") as String;

    // Condition
    String? condition = node.getAttribute('condition');
    
    return OPAFValue(uniqueId, name, value, condition);
  }
}