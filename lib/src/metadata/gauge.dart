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

class Gauge {

  static final supportedUnits = [
      'cm',
      'mm',
      'in',
  ];

  String units;
  int width;
  int? height;
  int stitches;
  int? rows;
  String? description;

  Gauge(this.units, this.width, this.stitches);

  void toXml(XmlBuilder builder) {
    builder.element("gauge", nest:() {
      builder.attribute("units", units);
      builder.attribute("width", width.toString());

      if (height != null) {
        builder.attribute("height", height.toString());
      }

      builder.attribute("stitches", stitches.toString());

      if (rows != null) {
        builder.attribute("rows", rows.toString());
      }

      if (description != null) {
        builder.attribute("description", description);
      }
    });
  }

  static Gauge parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'gauge') {
      throw OPAFParserException("Expected node with name 'gauge' and got '${node.name}'");
    }

    if (node.getAttribute('units') == null) {
      throw OPAFParserException("Attribute 'unit' missing from 'gauge' element");
    }

    if (node.getAttribute('width') == null) {
      throw OPAFParserException("Attribute 'width' missing from 'gauge' element");
    }

    if (node.getAttribute('stitches') == null) {
      throw OPAFParserException("Attribute 'stitches' missing from 'stitches' element");
    }

    String units = node.getAttribute('units') as String;

    if (!supportedUnits.contains(units)) {
      throw OPAFParserException("Gauge unit '$units' is not supported");
    }

    int? width = int.tryParse(node.getAttribute('width') as String);
    int? stitches = int.tryParse(node.getAttribute('stitches') as String);

    if (width == null) {
      throw OPAFParserException("Gauge attribute 'width' is not valid");
    }

    if (stitches == null) {
      throw OPAFParserException("Gauge attribute 'stitches' is not valid");
    }

    Gauge gauge = Gauge(units, width, stitches);

    if (node.getAttribute('height') != null) {
      gauge.height = int.tryParse(node.getAttribute('height') as String);
    }
    
    if (node.getAttribute('rows') != null) {
      gauge.rows = int.tryParse(node.getAttribute('rows') as String);
    }

    gauge.description = node.getAttribute('description');

    return gauge;
  }
}