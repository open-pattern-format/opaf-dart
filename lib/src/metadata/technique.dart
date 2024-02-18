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

import 'package:string_validator/string_validator.dart';
import 'package:xml/xml.dart';

import '../opaf_exceptions.dart';

class Technique {
  String name;
  String? description;
  String? url;

  Technique(this.name);

  void toXml(XmlBuilder builder) {
    builder.element("technique", nest:() {
      builder.attribute("name", name);

      if (description != null) {
        builder.attribute("description", description);
      }

      if (url != null) {
        builder.attribute("url", url);
      }
    });
  }

  static Technique parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'technique') {
      print("Expected node with name 'technique' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.getAttribute('name') == null) {
      print("Attribute 'name' missing from technique element");
      throw OPAFParserException();
    }

    String name = node.getAttribute('name') as String;

    Technique technique = Technique(name);
    technique.description = node.getAttribute('description');

    if (node.getAttribute('url') != null) {
      String url = node.getAttribute('url') as String;

      if (isURL(url)) {
        technique.url = url;
      }
    }

    return technique;
  }
}