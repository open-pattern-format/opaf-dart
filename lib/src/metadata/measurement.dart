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

class Measurement {

  static final supportedUnits = [
      'm',
      'cm',
      'mm',
      'yd',
      'in',
      'kg',
      'g',
      'mg',
      'oz',
      'lb'
  ];

  String name;
  String units;
  num value;

  Measurement(this.name, this.units, this.value);

  void toXml(XmlBuilder builder) {
    builder.element("measurement", attributes: {"name": name, "units": units, "value": value.toString()});
  }

  static Measurement parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'measurement') {
      print("Expected node with name 'measurement' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.getAttribute('name') == null) {
      print("Attribute 'name' missing from 'measurement' element");
      throw OPAFParserException();
    }

    if (node.getAttribute('units') == null) {
      print("Attribute 'units' missing from 'measurement' element");
      throw OPAFParserException();
    }

    if (node.getAttribute('value') == null) {
      print("Attribute 'value' missing from 'measurement' element");
      throw OPAFParserException();
    }

    String name = node.getAttribute('name') as String;
    String units = node.getAttribute('units') as String;
    num? value = num.tryParse(node.getAttribute('value') as String);

    if (value == null) {
      print("Measurement 'value' is not a valid number");
      throw OPAFParserException();
    }

    if (!supportedUnits.contains(units)) {
      print("Measurement unit '$units' is not supported");
      throw OPAFParserException();
    }

    return Measurement(name, units, value);
  }
}