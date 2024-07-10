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

  OPAFChart(this.name, this.rows);

  static OPAFChart parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (!node.name.local.contains('chart')) {
      print("Expected node with name 'opaf:define_chart' or 'chart' and got '${node.name}'");
      throw OPAFParserException();
    }
  
    if (node.getAttribute('name') == null) {
      print("Name attribute not found for chart");
      throw OPAFParserException();
    }
  
    // Check node
    OPAFUtils.checkNode(node, chartNodes);
    
    OPAFChart chart = OPAFChart(
      node.getAttribute("name") as String,
      [],
    );
    
    // Rows
    for (var e in node.childElements) {
      chart.rows.add(ChartRow.parse(e));
    }

    if (chart.rows.isEmpty) {
      print("Chart with name ${chart.name} is empty or contains no valid rows");
      throw OPAFParserException();
    }

    return chart;
  }
}