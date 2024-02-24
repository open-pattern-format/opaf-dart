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

import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import 'opaf_action.dart';
import 'opaf_block.dart';
import 'opaf_chart.dart';
import 'opaf_component.dart';
import 'opaf_document.dart';
import 'opaf_exceptions.dart';
import 'opaf_utils.dart';


class OPAFCompiler {

  static final protectedAttributes = [
      'opaf',
      'condition',
      'name',
      'repeat',
  ];

  OPAFDocument opafDoc;
  Map<String, dynamic> customValues = {};
  Map<String, dynamic> globalValues = {};

  OPAFCompiler(this.opafDoc, this.customValues);

  void processValues(XmlBuilder builder) {
    for (var v in opafDoc.opafValues) {
      // Check condition
      if (v.condition != null) {
        if (!OPAFUtils.evaluateCondition(v.condition as String, globalValues)) {
          continue;
        }
      }

      if (customValues.keys.contains(v.name)) {
        if (!v.config) {
          print("${v.name} is not a configurable value");
          throw OPAFInvalidException();
        }

        if (v.allowedValues.isNotEmpty && !v.allowedValues.contains(customValues[v.name])) {
          print("${customValues[v.name]} is not a valid value for ${v.name}");
          throw OPAFInvalidException();
        }

        globalValues[v.name] = OPAFUtils.strToNum(customValues[v.name]);
      } else {
        globalValues[v.name] = OPAFUtils.strToNum(
          OPAFUtils.evaluateExpr(v.value, globalValues)
        );
      }

      // Add config to project
      if (v.config) {
        builder.element("config", nest:() {
          builder.attribute("name", v.name);
          builder.attribute("value", globalValues[v.name].toString());
        });
      }
    }
  }

  void processColors(XmlBuilder builder) {
    for (var c in opafDoc.opafColors) {
      builder.element("color", nest:() {
        builder.attribute('name', c.name);
        builder.attribute('value', c.value);
      });
    }
  }

  List<XmlElement> processAction(XmlElement node, Map<String, dynamic> values) {
    // Get action object
    if (node.getAttribute('name') == null) {
      print("Attribute 'name' not found for action node");
      return [];
    }

    String name = node.getAttribute('name') as String;
    OPAFAction? action = opafDoc.getOpafAction(name);

    if (action == null) {
      print("Action with name '$name' could not be found.");
      return [];
    }

    // Process parameters
    var params = Map.of(action.params);

    for (var a in node.attributes) {
      if (protectedAttributes.contains(a.localName)) {
        continue;
      }

      params[a.localName] = OPAFUtils.strToNum(
        OPAFUtils.evaluateExpr(a.value, values)
      );
    }

    // Check parameters
    for (var p in params.keys) {
      if (params[p] == "") {
        print("Parameter '$p' is not defined for action '$name'");
        throw OPAFNotDefinedException();
      }
    }

    OPAFUtils.validateParams(opafDoc, params);

    List<XmlElement> nodes = [];
    
    for (var e in action.elements) {
      XmlDocumentFragment f = XmlDocumentFragment.parse(e);

      for (var c in f.childElements) {
        // Check condition
        if (!OPAFUtils.evaluateNodeCondition(c, params)) {
          continue;
        }

        c.removeAttribute("condition");

        // Evaluate attributes
        for (var a in c.attributes) {
          c.setAttribute(a.localName, OPAFUtils.evaluateExpr(a.value, params));
        }
        
        nodes.add(c);
      }
    }

    return nodes;
  }

  List<XmlElement> processImage(XmlElement node) {
    if (node.getAttribute('name') == null) {
      print("Attribute 'name' missing from image node");
      return [];
    }

    String name = node.getAttribute('name') as String;

    if (opafDoc.getOpafImageByName(name) == null) {
      print("Unable to find image with name '$name'");
      return [];
    }

    final builder = XmlBuilder();
  
    builder.element("image", nest: () {
      builder.attribute("name", name);

      if (node.getAttribute("tag") != null) {
        builder.attribute("tag", node.getAttribute("tag") as String);
      }

      if (node.getAttribute("caption") != null) {
        builder.attribute("caption", node.getAttribute("caption") as String);
      }
    });

    return builder.buildFragment().childElements.toList();
  }

  List<XmlElement> processText(XmlElement node, Map<String, dynamic> values) {
    final builder = XmlBuilder();

    builder.element("text", nest: () {
      if (node.getAttribute("data") != null) {
        builder.attribute(
          "data",
          OPAFUtils.evaluateExpr(node.getAttribute("data") as String, values)
        );
      }
    });

    return builder.buildFragment().childElements.toList();
   }

  List<XmlElement> processRow(XmlElement node, Map<String, dynamic> values) {
    // Check type
    if (node.getAttribute("type") == null) {
      print("Row attribute 'type' not found.");
      throw OPAFInvalidException();
    }

    List<XmlElement> nodes = [];

    // Default parameters
    if (globalValues.containsKey("opaf_prev_row_count")) {
      values["opaf_prev_row_count"] = globalValues["opaf_prev_row_count"];
    }

    if (globalValues.containsKey("opaf_prev_row_offset")) {
      values["opaf_prev_row_offset"] = globalValues["opaf_prev_row_offset"];
    }

    for (var c in node.childElements) {
      nodes.addAll(processNode(c, values));
    }

    // Calculate row count
    int offset = 0;

    if (node.getAttribute('offset') != null) {
      offset = int.tryParse(OPAFUtils.evaluateExpr(node.getAttribute('offset') as String, values)) ?? 0;
    }

    int count = OPAFUtils.getStitchCount(nodes) + offset;
    globalValues['opaf_prev_row_count'] = count;
    globalValues['opaf_prev_row_offset'] = offset;

    final builder = XmlBuilder();
    builder.element("row", nest: () {
      builder.attribute("type", node.getAttribute("type"));
      builder.attribute("count", count.toString());

      for (var a in node.attributes) {
        if (protectedAttributes.contains(a.localName)
        || a.localName == 'offset') {
          continue;
        }

        builder.attribute(a.localName, OPAFUtils.evaluateExpr(a.value, values));
      }

      for (var n in nodes) {
        builder.xml(n.toXmlString());
      }
    });

    return builder.buildFragment().childElements.toList();
  }

  List<XmlElement> processChart(node, values) {
    // Get chart object
    String name = node.getAttribute('name');
    OPAFChart? chart = opafDoc.getOpafChart(name);

    if (chart == null) {
      print("Unable to find chart with name '$name'");
      return [];
    }

    // Attributes
    int rowNum = node.getAttribute('row') == null ? 0 :
    OPAFUtils.strToNum(
      OPAFUtils.evaluateExpr(
          node.getAttribute('row'),
          values
      )
    );

    int count = node.getAttribute('count') == null ? 0 :
    OPAFUtils.strToNum(
      OPAFUtils.evaluateExpr(
        node.getAttribute('count'),
        values
      )
    ).round();
  
    int offset = node.getAttribute('offset') == null ? 0 :
    OPAFUtils.strToNum(
      OPAFUtils.evaluateExpr(
        node.getAttribute('offset'),
        values
      )
    ).round();
  
    // Check row number has been specified
    if (rowNum == 0) {
      print("opaf:chart received an invalid or missing 'row' attribute");
      throw OPAFInvalidException();
    }

    // Check stitch count is valid
    if (count == 0) {
      print("opaf:chart received an invalid or missing 'count' attribute.");
      throw OPAFInvalidException();
    }

    // Parse rows
    List<XmlElement> rows = [];

    for (var r in chart.rows) {
      var rNode = XmlDocumentFragment.parse(r);

      if (OPAFUtils.evaluateNodeCondition(rNode.firstElementChild as XmlElement, values)) {
        rows.add(rNode.firstElementChild as XmlElement);
      }
    }

    // Get row and actions
    if (rowNum > rows.length) {
      print("opaf:chart - row specified is invalid.");
      throw OPAFInvalidException();
    }

    var row = rows[rowNum - 1];
    List<XmlElement> rowActions = [];

    for (var a in row.findAllElements('opaf:action')) {
      if (a.getAttribute('name') == 'none') {
        continue;
      }

      if (OPAFUtils.evaluateNodeCondition(a, values)) {
        rowActions.add(a);
      }
    }

    if (rowActions.isEmpty) {
      print("opaf:chart - no actions found for specified row");
      throw OPAFInvalidException();
    }

    // Processed actions
    List<XmlElement> pActions = [];
    int rowCount = 0;

    for (var a in rowActions) {
      var pNodes = processNode(a, values);

      for (var pn in pNodes) {
        rowCount += int.parse(pn.getAttribute('total') as String);
        pActions.add(pn);
      }
    }

    if (offset > rowCount) {
      print("opaf:chart - offset is greater than requested row stitch count");
    }

    List<XmlElement> nodes = [];

    // Handle offset
    if (offset > 0) {
      for (var i = 0; i < pActions.length; i++) {
        var pa = pActions[i];

        int pCount = int.parse(pa.getAttribute('count') as String);
        int pTotal = int.parse(pa.getAttribute('total') as String);

        // Check if offset is reached
        if (offset == 0 && count >= pTotal) {
          nodes.add(pa);
          count -= pTotal;
          continue;
        }

        if ((pTotal / pCount).round() > offset) {
          print("opaf:chart - offset is invalid");
          throw OPAFInvalidException();
        }

        if (pTotal <= offset) {
          offset -= pTotal;
          continue;
        }

        // Refactor action for offset or stitch count
        var a = rowActions[i];

        int aCount;

        if (offset == 0) {
          aCount = (pCount / pTotal).round() * count;
          count -= ((pTotal / pCount).round() * count);
        } else {
          aCount = (pCount / pTotal).round() * offset;
          count -= ((pTotal / pCount).round() * offset);
        }

        a.setAttribute('count', aCount.toString());
        nodes.addAll(processAction(a, values));
      }
    }

    // Work out number of row repeats for stitch count
    if (count > 0) {
      int repeatCount = (count / rowCount).floor();

      if (repeatCount > 0) {
        final builder = XmlBuilder();
        builder.element('repeat', nest: () {
          builder.attribute('count', repeatCount.toString());

          for (var ra in pActions) {
            builder.xml(ra.toXmlString());
          }
        });

        nodes.addAll(builder.buildFragment().childElements);

        // Update stitch count
        count -= repeatCount * rowCount;
      }
    }

    // Work out remaining stitches
    if (count > 0) {
      for (var i = 0; i < pActions.length; i++) {
        if (count == 0) {
          break;
        }

        var pa = pActions[i];

        int pCount = int.parse(pa.getAttribute('count') as String);
        int pTotal = int.parse(pa.getAttribute('total') as String);

        if ((pTotal / pCount).round() > count) {
          print("opaf:chart - cannot return desired stitch count");
          throw OPAFInvalidException();
        }

        if (pTotal <= count) {
          nodes.add(pa);
          count -= pTotal;
          continue;
        }

        // Refactor action for stitch count
        var a = rowActions[i];
        int aCount = (pCount / pTotal).round() * count;
        a.setAttribute('count', aCount.toString());
        nodes.addAll(processAction(a, values));

        break;
      }
    }

    OPAFUtils.addChartAttribute(nodes, name, rowNum - 1);

    return nodes;
  }

  List<XmlElement> processBlock(node, values) {
    if (node.getAttribute('name') == null) {
      print("Attribute 'name' missing from block node");
      return [];
    }

    String name = node.getAttribute("name");
    OPAFBlock? block = opafDoc.getOpafBlock(name);

    if (block == null) {
      print("Unable to find block with name '$name'");
      return [];
    }

    // Repeat
    int repeat = 1;

    if (node.getAttribute("repeat") != null) {
      repeat = int.tryParse(OPAFUtils.evaluateExpr(node.getAttribute("repeat"), values)) ?? 1;
    }

    Map<String, dynamic> params = Map.of(block.params);

    for (var a in node.attributes) {
      if (protectedAttributes.contains(a.localName)) {
        continue;
      }

      params[a.localName] = OPAFUtils.strToNum(
        OPAFUtils.evaluateExpr(a.value, values)
      );
    }

    // Check parameters
    for (var p in params.keys) {
      if (params[p] == "") {
        print("Parameter '$p' is not defined for block '$name'");
        throw OPAFNotDefinedException();
      }
    }

    params["repeat_total"] = repeat;

    // Process elements the required number of times handling repeats
    List<List<XmlElement>> nodeArr = [];

    for (var i = 1; i <= repeat; i++) {
      List<XmlElement> nodes = [];

      // Default parameters
      params["repeat"] = i;

      for (var e in block.elements) {
        var element = XmlDocumentFragment.parse(e);

        for (var ec in element.childElements) {
          nodes.addAll(processNode(ec, params));
        }
      }

      nodeArr.add(nodes);
    }

    final builder = XmlBuilder();

    if (OPAFUtils.containsDuplicates(nodeArr)) {
      var (sortedNodes, repeats) = OPAFUtils.sortNodeArray(nodeArr);

      for (var i = 0; i < sortedNodes.length; i++) {
        if (repeats[i] > 1) {
          builder.element("repeat", nest: () {
            builder.attribute("count", repeats[i]);

            for (var n in sortedNodes[i]) {
              builder.xml(n.toXmlString());
            }
          });
        } else {
          for (var n in sortedNodes[i]) {
            builder.xml(n.toXmlString());
          }
        }
      }
    } else {
      for (var a in nodeArr) {
        for (var e in a) {
          builder.xml(e.toXmlString());
        }
      }
    }

    return builder.buildFragment().childElements.toList();
  }

  List<XmlElement> processNode(XmlElement node, Map<String, dynamic> values) {
    List<XmlElement> nodes = [];
  
    if (OPAFUtils.evaluateNodeCondition(node, values)) {
      if (node.localName == 'action') {
        nodes.addAll(processAction(node, values));
      } else if (node.localName == "image") {
        nodes.addAll(processImage(node));
      } else if (node.localName == "text") {
        nodes.addAll(processText(node, values));
      } else if (node.localName == "block") {
        nodes.addAll(processBlock(node, values));
      } else if (node.localName == "row") {
        nodes.addAll(processRow(node, values));
      } else if (node.localName == "chart") {
        nodes.addAll(processChart(node, values));
      }
    }

    return nodes;
  }

  List<XmlElement> processComponent(OPAFComponent c) {
    List<XmlElement> nodes = [];

    for (var e in c.elements) {
      XmlDocumentFragment f = XmlDocumentFragment.parse(e);

      for (var n in f.childElements) {
        nodes.addAll(processNode(n, globalValues));
      }
    }

    // Row IDs
    OPAFUtils.addIdAttribute(nodes, ["row"], 0);

    final builder = XmlBuilder();
    builder.element("component", nest: () {
        builder.attribute("name", c.name);
        builder.attribute("unique_id", c.uniqueId);

        for (var c in nodes) {
          builder.xml(c.toXmlString());
        }
    });
    
    return builder.buildFragment().childElements.toList();
  }

  XmlDocument compile() {
    if (opafDoc.pkgVersion == null) {
      throw OPAFNotPackagedException();
    }

    if (!customValues.containsKey('name')) {
      throw OPAFInvalidException();
    }

    final builder = XmlBuilder();

    // Set root element
    builder.processing('xml', 'version="1.0"');
    builder.element("project", nest: () {
      builder.attribute("name", customValues['name']);
      builder.attribute("unique_id", Uuid().v4());

      // Images
      if (opafDoc.opafImages.isNotEmpty) {
        for (var i in opafDoc.opafImages) {
          builder.element("image", attributes: {"name": i.name, "data": base64Encode(i.data)});
        }
      }

      // Pattern
      builder.element("pattern", nest: () {
        builder.attribute("unique_id", opafDoc.uniqueId);
        builder.attribute("name", opafDoc.name);
        builder.attribute("version", opafDoc.version);

        // Metadata
        builder.element("metadata", nest:() {
          opafDoc.metadata.toXml(builder);
        });
      });

      processValues(builder);
      processColors(builder);

      // Process charts
      for (var chart in opafDoc.opafCharts) {
        var chartNodes = [];

        builder.element("chart", nest: () {
          builder.attribute('name', chart.name);

          for (var r in chart.rows) {
            var row = XmlDocumentFragment.parse(r);

            for (var c in row.childElements) {
              chartNodes.addAll(processNode(c, globalValues));
            }
          }

          for (var n in chartNodes) {
            builder.xml(n.toXmlString());
          }
        });
      }

      // Process components
      for (var c in opafDoc.opafComponents){
        if (c.condition != null) {
          if (!OPAFUtils.evaluateCondition(c.condition as String, globalValues)) {
            continue;
          }
        }

        List<XmlElement> elements = processComponent(c);

        for (var e in elements) {
          builder.xml(e.toXmlString());
        }
      }
    });
    
    return builder.buildDocument();
  }
}