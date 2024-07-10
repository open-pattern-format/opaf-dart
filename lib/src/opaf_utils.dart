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

import 'dart:io';

import 'package:opaf/opaf.dart';
import 'package:path/path.dart' as p;
import 'package:string_validator/string_validator.dart';
import 'package:xml/xml.dart';
import 'package:expressions/expressions.dart';

import 'opaf_color.dart';
import 'opaf_document.dart';
import 'opaf_exceptions.dart';
import 'opaf_image.dart';
import 'opaf_funcs.dart';


class OPAFUtils {

  static final supportedNodes = [
      'define_action',
      'define_block',
      'define_chart',
      'define_color',
      'define_image',
      'define_value',
      'action',
      'block',
      'chart',
      'component',
      'image',
      'instruction',
      'repeat',
      'row',
      'text'
  ];


static String? parseUri(String uri, String? dir) {
  var splitUri = uri.split('://');

  if (splitUri.length != 2) {
    return null;
  }

  // Get absolute path
  if (splitUri[0] == "file") {
    File file = File(splitUri[1]);

    if (file.isAbsolute) {
      return file.absolute.path;
    } else {
      return dir == null ? file.absolute.path : p.join(dir, splitUri[1]);
    }
  }

  return null;
}


  static String evaluateExpr(String expr, Map<String, dynamic> values) {
    var pattern = RegExp(r"[$][{](.*?)[}]");

    if (pattern.hasMatch(expr)) {
      for (var m in pattern.allMatches(expr)) {
        Expression e = Expression.parse(m[1] as String);

        Map<String, dynamic> context = {
          "ROUND": OPAFFuncs.round,
          "MROUND": OPAFFuncs.mround,
          "FLOOR": OPAFFuncs.floor,
          "CEIL": OPAFFuncs.ceil,
          "LT": OPAFFuncs.less,
          "GT": OPAFFuncs.greater,
          "EQ": OPAFFuncs.equals,
          "NEQ": OPAFFuncs.notEquals,
          "AND": OPAFFuncs.and,
          "OR": OPAFFuncs.or,
          "NOT": OPAFFuncs.not,
          "ABS": OPAFFuncs.abs,
          "CHOOSE": OPAFFuncs.choose,
          "LCHOOSE": OPAFFuncs.loopChoose,
          "ISEMPTY": OPAFFuncs.isEmpty,
        };
        
        for (String s in values.keys) {
          context[s] = strToNum(values[s]);
        }

        var result = ExpressionEvaluator().eval(e, context);

        expr = expr.replaceAll(m[0] as String, result.toString());
      }
    }

    return expr;
  }

  static bool evaluateCondition(String condition, Map<String, dynamic> values) {
    String result = evaluateExpr(condition, values);
    return toBoolean(result.toLowerCase());
  }

  static bool evaluateNodeCondition(String? condition, Map<String, dynamic> values) {
    if (condition != null) {
      return evaluateCondition(condition, values);
    }

    return true;
  }

  static void validateParams(OPAFDocument doc, Map<String, dynamic> params) {
    // Check color
    if (params.containsKey('color')) {
      var colors = doc.getOpafColors();

      if (!colors.containsKey(params['color'])) {
        print("Color '$params['color]' is not defined");
        throw OPAFNotDefinedException();
      }
    }
  }

  static dynamic strToNum(dynamic val) {
    if (val is String) {
      var intVal = int.tryParse(val);

      if (intVal != null) {
        return intVal;
      }

      var dblVal = double.tryParse(val);

      if (dblVal != null) {
        return dblVal;
      }
    }

    return val;
  }

  static XmlNode checkNode(XmlElement node, List<String> allowedNodes) {
    if (node.childElements.isEmpty) {
        return node;
    }

    for (var child in node.childElements) {
      if (child.nodeType != XmlNodeType.ELEMENT) {
          child.remove();
          continue;
      }

      if (child.name.prefix != null) {
        if (child.name.prefix != "opaf") {
          print("Node with name '${child.name}' is not recognized");
          throw OPAFInvalidException();
        }
      }

      if (!supportedNodes.contains(child.name.local)) {
        print("Node with name '${child.name.local}' not recognized");
        throw OPAFInvalidException();
      }

      if (allowedNodes.isNotEmpty) {
        if (!allowedNodes.contains(child.name.local)) {
          print("Node with name '${child.name.local}' is not allowed in this scope");
          throw OPAFInvalidException();
        }
      }

      if (child.childElements.isNotEmpty) {
          checkNode(child, allowedNodes);
      }
    }

    return node;
  }

  static String paramsToString(Map<String, dynamic> params) {
    List<String> paramStrings = [];

    for (var param in params.keys) {
      if (params[param] == '') {
        paramStrings.add(param);
      } else {
        paramStrings.add('$param=${params[param]}');
      }
    }

    return paramStrings.join(' ');
  }

  static (List<List<XmlElement>>, List<int>) sortNodeArray(List<List<XmlElement>> nodeArr) {
    // Store nodes and number of adjacent repeats
    List<List<XmlElement>> nodeArrays = [];
    List<int> repeats = [];
    int count = 1;

    // Iterate through each node array
    for (var arr in nodeArr) {
      // Check if the current node is the same as the previous
      if (nodeArrays.isNotEmpty) {
        if (nodeArrToString(arr) == nodeArrToString(nodeArrays.last)) {
          count += 1;
          continue;
        } else {
          nodeArrays.add(arr);

          // Reset repeat count
          repeats.add(count);
          count = 1;
        }
      } else {
        nodeArrays.add(arr);
      }
    }

    // Add final node repeat count
    repeats.add(count);

    return (nodeArrays, repeats);
  }

  static String nodeArrToString(List<XmlElement> arr) {
    String result = "";

    for (var n in arr) {
      result += n.toString();
    }

    return result;
  }

  static bool containsDuplicates(List<List<XmlElement>> arr) {
    if (arr.length <= 1) {
      return false;
    }

    // Create string array
    List<String> strArr = [];

    for (var a in arr) {
      strArr.add(nodeArrToString(a));
    }

    for (var i = 1; i < strArr.length; i++) {
      if (strArr[i] == strArr[i - 1]) {
        return true;
      }
    }

    return false;
  }

  static void addChartAttribute(List<XmlElement> nodes, String name, int row) {
    for (var n in nodes) {
      if (n.localName == 'action') {
        n.setAttribute('chart', '$name:$row');
      }

      if (n.childElements.isNotEmpty) {
        addChartAttribute(n.childElements.toList(), name, row);
      }
    }
  }

  static int getStitchCount(List<XmlElement> nodes) {
    int count = 0;

    for (var n in nodes) {
      if (n.localName == "action") {
        if (n.getAttribute("total") != null) {
          count += int.tryParse(n.getAttribute("total") as String) ?? 0;
        }
      }

      if (n.localName == "repeat") {
        if (n.getAttribute("count") != null) {
          int rCount = int.tryParse(n.getAttribute('count') as String) ?? 0;
          count += (rCount * getStitchCount(n.childElements.toList()));
        }
      }
    }

    return count;
  }

  static int getActionTotal(List<dynamic> actions) {
    int aCount = 0;

    for (var a in actions) {
      if (a is PatternAction) {
        aCount += int.tryParse(a.total ?? '0') ?? 0;
      } else if (a is PatternRepeat) {
        aCount += getActionTotal(a.elements);
      }
    }

    return aCount;
  }

  static int getChartColumnCount(List<ChartRow> rows) {
    int maxCount = 0;

    for (var r in rows) {
      int rCount = getActionTotal(r.elements);

      if (rCount > maxCount) {
        maxCount = rCount;
      }
    }

    return maxCount;
  }

  static OPAFImage? getImageByName(List<OPAFImage> images, String name) {
    for (var i in images) {
      if (i.name == name) {
        return i;
      }
    }

    return null;
  }

  static OPAFColor? getColorByName(List<OPAFColor> colors, String name) {
    for (var c in colors) {
      if (c.name == name) {
        return c;
      }
    }

    return null;
  }

  static OPAFChart? getChartByName(List<OPAFChart> charts, String name) {
    for (var c in charts) {
      if (c.name == name) {
        return c;
      }
    }

    return null;
  }
}