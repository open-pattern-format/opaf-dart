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
import 'opaf_component.dart';
import 'opaf_document.dart';
import 'opaf_exceptions.dart';
import 'opaf_utils.dart';


class OPAFCompiler {

  static final protectedAttributes = [
      'opaf',
      'condition',
      'name',
  ];

  OPAFDocument opafDoc;
  Map<String, dynamic> customConfig = {};
  Map<String, dynamic> globalValues = {};

  OPAFCompiler(this.opafDoc, this.customConfig);

  void processConfig(XmlBuilder builder) {
    for (var c in opafDoc.opafConfigs) {
      if (customConfig.keys.contains(c.name)) {
        if (c.allowedValues.isNotEmpty && !c.allowedValues.contains(customConfig[c.name])) {
          print("${customConfig[c.name]} is not a valid value for ${c.name}");
          throw OPAFInvalidException();
        }

        globalValues[c.name] = OPAFUtils.strToNum(customConfig[c.name]);
      } else {
        globalValues[c.name] = OPAFUtils.strToNum(
          OPAFUtils.evaluateExpr(c.value, globalValues)
        );
      }

      // Add config to project
      builder.element("config", nest:() {
        builder.attribute("name", c.name);
        builder.attribute("value", globalValues[c.name].toString());
      });
    }
  }

  void processValues(XmlBuilder builder) {
    for (var v in opafDoc.opafValues) {
      // Check condition
      if (v.condition != null) {
        if (!OPAFUtils.evaluateCondition(v.condition as String, globalValues)) {
          continue;
        }
      }

      globalValues[v.name] = OPAFUtils.strToNum(
        OPAFUtils.evaluateExpr(v.value, globalValues)
      );
    }
  }

  void processColors(XmlBuilder builder) {
    for (var c in opafDoc.opafColors) {
      builder.element("color", nest:() {
        builder.attribute('name', c.name);
        builder.attribute('value', c.value);
        builder.attribute('description', c.description);
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

        if (params.containsKey('chart')) {
          c.setAttribute('chart', params['chart']);
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

  List<XmlElement> processInstruction(XmlElement node, Map<String, dynamic> values) {
    // Check type
    if (node.getAttribute("type") == null) {
      print("Instruction attribute 'type' not found.");
      throw OPAFInvalidException();
    }

    List<XmlElement> nodes = [];

    for (var c in node.childElements) {
      nodes.addAll(processNode(c, values));
    }

    final builder = XmlBuilder();
    builder.element("instruction", nest: () {
      builder.attribute("type", node.getAttribute("type"));

      for (var a in node.attributes) {
        if (protectedAttributes.contains(a.localName)) {
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

  List<XmlElement> processRepeat(XmlElement node, Map<String, dynamic> values) {
    // Check count
    if (node.getAttribute("count") == null) {
      print("Repeat attribute 'count' not found.");
      throw OPAFInvalidException();
    }

    List<XmlElement> nodes = [];

    for (var c in node.childElements) {
      nodes.addAll(processNode(c, values));
    }

    final builder = XmlBuilder();
    builder.element("repeat", nest: () {
      for (var a in node.attributes) {
        if (protectedAttributes.contains(a.localName)) {
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

  List<XmlElement> processRow(XmlElement node, Map<String, dynamic> values) {
    // Check type
    if (node.getAttribute("type") == null) {
      print("Row attribute 'type' not found.");
      throw OPAFInvalidException();
    }

    List<XmlElement> nodes = [];

    for (var c in node.childElements) {
      nodes.addAll(processNode(c, values));
    }

    final builder = XmlBuilder();
    builder.element("row", nest: () {
      builder.attribute("type", node.getAttribute("type"));

      for (var a in node.attributes) {
        if (protectedAttributes.contains(a.localName)) {
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

    // Add global values
    params.addAll(globalValues);

    // Process elements
    List<XmlElement> nodes = [];

    for (var e in block.elements) {
      var element = XmlDocumentFragment.parse(e);

      for (var ec in element.childElements) {
        nodes.addAll(processNode(ec, params));
      }
    }

    final builder = XmlBuilder();

    for (var n in nodes) {
      builder.xml(n.toXmlString());
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
      } else if (node.localName == "instruction") {
        nodes.addAll(processInstruction(node, values));
      } else if (node.localName == "row") {
        nodes.addAll(processRow(node, values));
      } else if (node.localName == "repeat") {
        nodes.addAll(processRepeat(node, values));
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

    if (!customConfig.containsKey('name')) {
      throw OPAFInvalidException();
    }

    final builder = XmlBuilder();

    // Set root element
    builder.processing('xml', 'version="1.0"');
    builder.element("project", nest: () {
      builder.attribute("name", customConfig['name']);
      builder.attribute("unique_id", Uuid().v4());

      // Images
      if (opafDoc.opafImages.isNotEmpty) {
        for (var i in opafDoc.opafImages) {
          if (i.data == null) {
            i.convert();
          }

          if (i.data != null) {
            builder.element("image", attributes: {"name": i.name, "data": base64Encode(i.data!)});
          }
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

      processConfig(builder);
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