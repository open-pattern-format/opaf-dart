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

class PatternText extends PatternElement {
  String data;

  PatternText(this.data);

  void toXml(XmlBuilder builder) {
    builder.element("opaf:text", nest:() {
      builder.attribute("data", data);
    });
  }

  PatternText clone() {
    PatternText newText = PatternText(
      data,
    );

    newText.condition = condition;

    return newText;
  }

  static PatternText parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'text') {
      throw OPAFParserException("Expected node with name 'opaf:text' and got '${node.name}'");
    }

    if (node.getAttribute('data') == null) {
      throw OPAFParserException("Attribute 'data' missing from text element");
    }

    PatternText text = PatternText(node.getAttribute('data') as String);

    if (node.getAttribute('condition') != null) {
      text.condition = node.getAttribute("condition") as String;
    }

    return text;
  }
}