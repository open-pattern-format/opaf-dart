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
import 'pattern/action.dart';
import 'pattern/block.dart';
import 'pattern/image.dart';
import 'pattern/instruction.dart';
import 'pattern/repeat.dart';
import 'pattern/row.dart';
import 'pattern/text.dart';


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

  List<XmlElement> processAction(PatternAction a, Map<String, dynamic> values) {
    // Get action object
    OPAFAction? action = opafDoc.getOpafAction(a.name);

    if (action == null) {
      print("Action with name ${a.name} could not be found.");
      return [];
    }

    // Process parameters
    Map<String, dynamic> params = Map.of(action.params);
    for (var p in params.keys) {
      if (a.params.containsKey(p)) {
        params[p] = OPAFUtils.strToNum(
          OPAFUtils.evaluateExpr(a.params[p], values)
        );
      }
    }

    // Check parameters
    for (var p in params.keys) {
      if (params[p] == "") {
        print("Parameter '$p' is not defined for action '${action.name}'");
        throw OPAFNotDefinedException();
      }
    }

    OPAFUtils.validateParams(opafDoc, params);

    List<XmlElement> nodes = [];
    
    for (var e in action.elements) {
      // Check condition
      if (!OPAFUtils.evaluateNodeCondition(e.condition, params)) {
        continue;
      }
      
      XmlElement element = XmlElement(XmlName("action"));
      element.setAttribute('name', OPAFUtils.evaluateExpr(e.name, params));

      // Evaluate attributes
      for (var a in e.params.keys) {
        element.setAttribute(a, OPAFUtils.evaluateExpr(e.params[a], params));
      }

      if (a.chart != null) {
        element.setAttribute('chart', a.chart as String);
      }

      if (e.total != null) {
        element.setAttribute('total', OPAFUtils.evaluateExpr(e.total!, params));
      }
      
      nodes.add(element);
    }

    return nodes;
  }

  List<XmlElement> processImage(PatternImage image) {
    if (opafDoc.getOpafImageByName(image.name) == null) {
      print("Unable to find image with name '${image.name}'");
      return [];
    }

    final builder = XmlBuilder();
  
    builder.element("image", nest: () {
      builder.attribute("name", image.name);

      if (image.caption != null) {
        builder.attribute("caption", image.caption as String);
      }
    });

    return builder.buildFragment().childElements.toList();
  }

  List<XmlElement> processText(PatternText element, Map<String, dynamic> values) {
    final builder = XmlBuilder();

    builder.element("text", nest: () {
      builder.attribute(
        "data",
        OPAFUtils.evaluateExpr(element.data, values)
      );
    });

    return builder.buildFragment().childElements.toList();
   }

  List<XmlElement> processInstruction(PatternInstruction instruction, Map<String, dynamic> values) {
    List<XmlElement> nodes = [];

    for (var c in instruction.elements) {
      nodes.addAll(processElement(c, values));
    }

    final builder = XmlBuilder();
    builder.element("instruction", nest: () {
      if (instruction.name != null) {
        builder.attribute("name", OPAFUtils.evaluateExpr(instruction.name as String, values));
      }

      for (var n in nodes) {
        builder.xml(n.toXmlString());
      }
    });

    return builder.buildFragment().childElements.toList();
  }

  List<XmlElement> processRepeat(PatternRepeat repeat, Map<String, dynamic> values) {
    List<XmlElement> nodes = [];

    for (var e in repeat.elements) {
      nodes.addAll(processElement(e, values));
    }

    final builder = XmlBuilder();
    builder.element("repeat", nest: () {
      builder.attribute('count', OPAFUtils.evaluateExpr(repeat.count, values));

      for (var n in nodes) {
        builder.xml(n.toXmlString());
      }
    });

    return builder.buildFragment().childElements.toList();
  }

  List<XmlElement> processRow(ChartRow row, Map<String, dynamic> values) {
    List<XmlElement> nodes = [];

    for (var e in row.elements) {
      nodes.addAll(processElement(e, values));
    }

    final builder = XmlBuilder();
    builder.element("row", nest: () {
      builder.attribute("type", row.type);

      for (var n in nodes) {
        builder.xml(n.toXmlString());
      }
    });

    return builder.buildFragment().childElements.toList();
  }

  List<XmlElement> processBlock(PatternBlock element, values) {
    OPAFBlock? block = opafDoc.getOpafBlock(element.name);

    if (block == null) {
      print("Unable to find block with name '${element.name}'");
      return [];
    }

    Map<String, dynamic> params = Map.of(block.params);

    for (var p in params.keys) {
      if (element.params.containsKey(p)) {
        params[p] = OPAFUtils.strToNum(
          OPAFUtils.evaluateExpr(element.params[p], values)
        );
      }
    }

    // Check parameters
    for (var p in params.keys) {
      if (params[p] == "") {
        print("Parameter '$p' is not defined for block '${block.name}'");
        throw OPAFNotDefinedException();
      }
    }

    // Add global values
    params.addAll(globalValues);

    // Process elements
    List<XmlElement> nodes = [];

    for (var e in block.elements) {
      nodes.addAll(processElement(e, params));
    }

    final builder = XmlBuilder();

    for (var n in nodes) {
      builder.xml(n.toXmlString());
    }

    return builder.buildFragment().childElements.toList();
  }

  List<XmlElement> processElement(dynamic element, Map<String, dynamic> values) {
    List<XmlElement> nodes = [];
  
    if (OPAFUtils.evaluateNodeCondition(element.condition, values)) {
      if (element is PatternAction) {
        nodes.addAll(processAction(element, values));
      } else if (element is PatternImage) {
        nodes.addAll(processImage(element));
      } else if (element is PatternText) {
        nodes.addAll(processText(element, values));
      } else if (element is PatternBlock) {
        nodes.addAll(processBlock(element, values));
      } else if (element is PatternInstruction) {
        nodes.addAll(processInstruction(element, values));
      } else if (element is ChartRow) {
        nodes.addAll(processRow(element, values));
      } else if (element is PatternRepeat) {
        nodes.addAll(processRepeat(element, values));
      }
    }

    return nodes;
  }

  List<XmlElement> processComponent(OPAFComponent c) {
    List<XmlElement> nodes = [];

    for (var e in c.elements) {
      nodes.addAll(processElement(e, globalValues));
    }

    final builder = XmlBuilder();
    builder.element("component", nest: () {
        builder.attribute("name", c.name);
        builder.attribute("unique_id", c.uniqueId);

        for (var n in nodes) {
          builder.xml(n.toXmlString());
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
            chartNodes.addAll(processElement(r, globalValues));
          }

          for (var n in chartNodes) {
            builder.xml(n.toXmlString());
          }
        });
      }

      // Process components
      print(opafDoc.opafComponents.length.toString());
      for (var c in opafDoc.opafComponents) {
        print(c.name.toUpperCase());
        if (c.condition != null) {
          if (!OPAFUtils.evaluateCondition(c.condition as String, globalValues)) {
            continue;
          }
        }

        print("YES");

        List<XmlElement> elements = processComponent(c);

        for (var e in elements) {
          builder.xml(e.toXmlString());
        }
      }
    });
    
    return builder.buildDocument();
  }
}