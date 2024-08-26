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

import '../opaf.dart';


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

  List<XmlElement> processConfigs() {
    List<XmlElement> elements = [];

    for (var c in opafDoc.opafConfigs) {
      elements.add(processConfig(c));
    }

    return elements;
  }

  XmlElement processConfig(OPAFConfig config) {
    if (customConfig.keys.contains(config.name)) {
      if (config.allowedValues.isNotEmpty && !config.allowedValues.contains(customConfig[config.name])) {
        throw OPAFInvalidException("${customConfig[config.name]} is not a valid value for ${config.name}");
      }

      globalValues[config.name] = OPAFUtils.strToNum(customConfig[config.name]);
    } else {
      globalValues[config.name] = OPAFUtils.strToNum(
        OPAFUtils.evaluateExpr(config.value, globalValues)
      );
    }

    XmlElement element = XmlElement(XmlName("config"));
    element.setAttribute('name', config.name);
    element.setAttribute('value', globalValues[config.name].toString());
  
    return element;
  }

  void processValues() {
    for (var v in opafDoc.opafValues) {
      processValue(v);
    }
  }

  void processValue(OPAFValue value) {
    // Check condition
    if (value.condition != null) {
      if (!OPAFUtils.evaluateCondition(value.condition as String, globalValues)) {
        return;
      }
    }

    globalValues[value.name] = OPAFUtils.strToNum(
      OPAFUtils.evaluateExpr(value.value, globalValues)
    );
  }

  List<XmlElement> processColors() {
    List<XmlElement> elements = [];

    for (var c in opafDoc.opafColors) {
      elements.add(processColor(c));
    }

    return elements;
  }

  XmlElement processColor(OPAFColor color) {
    XmlElement element = XmlElement(XmlName('color'));
    element.setAttribute('name', color.name);
    element.setAttribute('value', color.value);
    element.setAttribute('description', color.description);

    return element;
  }

  List<XmlElement> processAction(PatternAction a, Map<String, dynamic> values) {
    // Get action object
    OPAFAction? action = opafDoc.getOpafAction(a.name);

    if (action == null) {
      throw OPAFNotDefinedException("Action with name ${a.name} could not be found");
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
        throw OPAFNotDefinedException("Parameter '$p' is not defined for action '${action.name}'");
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

      // Chart attribute
      if (a.params.containsKey('chart')) {
        element.setAttribute('chart', OPAFUtils.evaluateExpr(a.params['chart'], params));
      }
      
      nodes.add(element);
    }

    return nodes;
  }

  List<XmlElement> processImage(PatternImage image) {
    if (opafDoc.getOpafImageByName(image.name) == null) {
      throw OPAFNotDefinedException("Unable to find image with name '${image.name}'");
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
      throw OPAFNotDefinedException("Unable to find block with name '${element.name}'");
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
        throw OPAFNotDefinedException("Parameter '$p' is not defined for block '${block.name}'");
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

  List<XmlElement> processChart(OPAFChart chart) {
    var chartNodes = [];

    final builder = XmlBuilder();
    builder.element("chart", nest: () {
      builder.attribute('name', chart.name);

      for (var r in chart.rows) {
        chartNodes.addAll(processElement(r, globalValues));
      }

      for (var n in chartNodes) {
        builder.xml(n.toXmlString());
      }
    });

    return builder.buildFragment().childElements.toList();
  }

  List<XmlElement> processComponent(OPAFComponent c) {
    List<XmlElement> nodes = [];

    if (c.condition != null) {
      if (!OPAFUtils.evaluateCondition(c.condition as String, globalValues)) {
        return nodes;
      }
    }

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
    if (!customConfig.containsKey('name')) {
      throw OPAFInvalidException("'name' not provided in custom configuration");
    }

    final builder = XmlBuilder();

    // Set root element
    builder.processing('xml', 'version="1.0"');
    builder.element("project", nest: () {
      builder.attribute("name", customConfig['name']);
      builder.attribute("unique_id", Uuid().v4());
      builder.attribute("spec_version", supportedSpec);

      // Images
      if (opafDoc.opafImages.isNotEmpty) {
        for (var i in opafDoc.opafImages) {
          if (i.data == null) {
            i.convert();
          }

          if (i.data == null) {
            throw OPAFException("Image with name '${i.name} 'failed to convert");
          }

          builder.element("image", attributes: {"name": i.name, "data": base64Encode(i.data!)});
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

      // Process configs
      for (var c in processConfigs()) {
        builder.xml(c.toXmlString());
      }

      processValues();
      
      // Process Colors
      for (var c in processColors()) {
        builder.xml(c.toXmlString());
      }

      // Process charts
      for (var chart in opafDoc.opafCharts) {
        for (var x in processChart(chart)) {
          builder.xml(x.toXmlString());
        }
      }

      // Process components
      for (var c in opafDoc.opafComponents) {
        for (var e in processComponent(c)) {
          builder.xml(e.toXmlString());
        }
      }
    });
    
    return builder.buildDocument();
  }
}