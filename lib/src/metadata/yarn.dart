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

class Yarn {
  String name;
  String? brand;
  String? weight;
  int? unitWeight;
  int? length;

  Yarn(this.name);

  void toXml(XmlBuilder builder) {
    builder.element("yarn", nest:() {
      builder.attribute("name", name);

      if (brand != null) {
        builder.attribute("brand", brand);
      }

      if (weight != null) {
        builder.attribute("weight", weight);
      }

      if (unitWeight != null) {
        builder.attribute("unit_weight", unitWeight.toString());
      }
  
      if (length != null) {
        builder.attribute("length", length.toString());
      }
    });
  }

  static Yarn parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'yarn') {
      throw OPAFParserException("Expected node with name 'yarn' and got '${node.name}'");
    }

    if (node.getAttribute('name') == null) {
      throw OPAFParserException("Attribute 'name' missing from 'yarn' element");
    }

    String name = node.getAttribute('name') as String;

    Yarn yarn = Yarn(name);
    yarn.brand = node.getAttribute('brand');
    yarn.weight = node.getAttribute('weight');

    if (node.getAttribute('unit_weight') != null) {
      yarn.unitWeight = int.tryParse(node.getAttribute('unit_weight') as String);
    }

    if (node.getAttribute('length') != null) {
      yarn.length = int.tryParse(node.getAttribute('length') as String);
    }

    return yarn;
  }
}