import 'dart:io';

import 'package:string_validator/string_validator.dart';
import 'package:xml/xml.dart';

import 'opaf_chart.dart';
import 'opaf_color.dart';
import 'opaf_exceptions.dart';
import 'opaf_image.dart';
import 'opaf_pattern.dart';

class OPAFProject {
  File file;
  XmlDocument xmlDoc;
  String name;
  String uniqueId;
  int progress = 0;
  OPAFPattern? pattern;
  Map<String, String> config = {};
  List<OPAFImage> images = [];
  List<OPAFColor> colors = [];
  List<OPAFChart> charts = [];

  OPAFProject(
    this.file,
    this.xmlDoc,
    this.name, 
    this.uniqueId,
    this.progress,
  );

  void parseConfig() {
    if (config.isNotEmpty) {
      return;
    }

    var node = xmlDoc.rootElement;

    for (var c in node.findElements('config')) {
      if (c.getAttribute('name') == null || c.getAttribute('value') == null) {
        continue;
      }

      config[c.getAttribute('name') as String] = c.getAttribute('value') as String;
    }
  }

  void parseCharts() {
    if (charts.isNotEmpty) {
      return;
    }

    var node = xmlDoc.rootElement;

    for (var c in node.findElements('chart')) {
      if (c.getAttribute('name') == null) {
        continue;
      }

      charts.add(OPAFChart.parse(c));
    }
  }

  void parseColors() {
    if (colors.isNotEmpty) {
      return;
    }

    var node = xmlDoc.rootElement;

    for (var c in node.findElements('color')) {
      colors.add(OPAFColor.parse(c));
    }
  }

  void updateColors() {
    var node = xmlDoc.rootElement;

    for (var c in node.findElements('color')) {
      var color = getColorByName(c.getAttribute('name') ?? '');

      if (color == null) {
        continue;
      }

      c.setAttribute('value', color.value);
    }
  }

  void parseImages() {
    if (images.isNotEmpty) {
      return;
    }

    var node = xmlDoc.rootElement;

    for (var i in node.findElements('image')) {
      images.add(OPAFImage.parse(i, null));
    }
  }

  void parsePattern() {
    if (pattern != null) {
      return;
    }

    var node = xmlDoc.rootElement;

    for (var p in node.findElements('pattern')) {
      pattern = OPAFPattern.parse(p);
    }
  }

  OPAFImage? getImageByName(String name) {
    for (var i in images) {
      if (i.name == name) {
        return i;
      }
    }

    return null;
  }

  OPAFColor? getColorByName(String name) {
    for (var c in colors) {
      if (c.name == name) {
        return c;
      }
    }

    return null;
  }

  OPAFChart? getChartByName(String name) {
    for (var c in charts) {
      if (c.name == name) {
        return c;
      }
    }

    return null;
  }

  void updateProgress() {
    var node = xmlDoc.rootElement;

    var ros = [];
    var mCount = 0;

    for (var c in node.findElements('component')) {
      int count = 0;
      var rs = [];

      rs.addAll(c.findAllElements('row'));

      if (rs.isEmpty) {
        continue;
      }

      for (var r in rs) {
        if (r.getAttribute('completed') != null) {
          if (toBoolean(r.getAttribute('completed'))) {
            count += 1;
          }
        }
      }

      // Update global variables
      ros.addAll(rs);
      mCount += count;

      // Update component
      c.setAttribute('completed', (count == rs.length).toString());
    }

    // Calculate overall progress
    if (ros.isNotEmpty) {
      progress = ((100 / ros.length) * mCount).round();
      node.setAttribute('progress', progress.toString());
    }
  }

  void saveToFile() {
    file.writeAsString(xmlDoc.toString());
  }

  static Future<OPAFProject> parse(String path) async {
    File file = File(path);
    var doc = XmlDocument.parse(await file.readAsString());

    var node = doc.rootElement;

    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.localName != 'project') {
      print("Expected node with name 'project' and got '${node.name}'");
      throw OPAFParserException();
    }
  
    if (node.getAttribute('name') == null) {
      print("Name attribute not found for project");
      throw OPAFParserException();
    }

    if (node.getAttribute('unique_id') == null) {
      print("Unique ID not defined for project");
      throw OPAFParserException();
    }
  
    String name = node.getAttribute("name") as String;
    String uniqueId = node.getAttribute("unique_id") as String;

    // Progress
    int? progress = int.tryParse(node.getAttribute("progress") ?? '0');
    
    return OPAFProject(file, doc, name, uniqueId, progress ?? 0);
  }
}