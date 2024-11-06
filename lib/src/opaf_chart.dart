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
import 'pattern/row.dart';

class OPAFChart {

  static final chartNodes = [
    'action',
    'repeat',
    'row',
  ];

  String name;
  List<ChartRow> rows;
  String? condition;

  OPAFChart(this.name, this.rows, this.condition);

  static OPAFChart parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (!node.name.local.contains('chart')) {
      throw OPAFParserException("Expected node with name 'opaf:define_chart' or 'chart' and got '${node.name}'");
    }
  
    if (node.getAttribute('name') == null) {
      throw OPAFParserException("Name attribute not found for chart");
    }
  
    // Check node
    OPAFUtils.checkNode(node, chartNodes);
    
    OPAFChart chart = OPAFChart(
      node.getAttribute("name") as String,
      [],
      node.getAttribute('condition'),
    );
    
    // Rows
    for (var e in node.childElements) {
      chart.rows.add(ChartRow.parse(e));
    }

    return chart;
  }
}