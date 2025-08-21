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
import 'package:string_validator/string_validator.dart';
import 'package:version/version.dart';
import 'package:xml/xml.dart';


class OPAFProject {
  File? file;
  XmlDocument xmlDoc;
  String name;
  String uniqueId;
  Version specVersion;
  int progress = 0;
  String notes;
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
    this.specVersion,
    this.progress,
    this.notes,
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
      var color = OPAFUtils.getColorByName(colors, c.getAttribute('name') ?? '');

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

  (int, int) getInstructionCount(XmlElement c) {
    int tCount = 0;
    int cCount = 0;

    for (var e in c.childElements) {
      if (e.localName == 'instruction') {
        if (e.getAttribute('completed') == null ? false : toBoolean(e.getAttribute('completed') as String)) {
          cCount += 1;
        }
        
        tCount += 1;
      }

      if (e.localName == 'repeat') {
        // Get repeat counters
        int rCount = int.tryParse(e.getAttribute('count') == null ? '0' : e.getAttribute('count') as String) ?? 0;
        int dCount = int.tryParse(e.getAttribute('counter') == null ? '0' : e.getAttribute('counter') as String) ?? 0;

        int rtCount = 0;
        int rcCount = 0;

        (rtCount, rcCount) = getInstructionCount(e);

        if (rCount < 2) {
          tCount += rtCount;
          cCount += rcCount;
        } else {
          tCount += (rCount * rtCount);

          if (rCount == dCount) {
            cCount += (dCount * rtCount);
          } else {
            cCount += (dCount * rtCount) + rcCount;
          }
        }
      }
    }

    return (tCount, cCount);
  }

  void updateProgress() {
    var node = xmlDoc.rootElement;

    var cCount = 0;
    var tCount = 0;

    for (var c in node.findElements('component')) {
      int ccCount = 0;
      int ctCount = 0;

      (ctCount, ccCount) = getInstructionCount(c);

      // Update totals
      tCount += ctCount;
      cCount += ccCount;

      // Update component
      c.setAttribute('completed', (ctCount == ccCount).toString());
    }

    // Calculate overall progress
    progress = ((100 / tCount) * cCount).round();
    node.setAttribute('progress', progress.toString());
  }

  void updateNotes(String notes) {
    var node = xmlDoc.rootElement;
    this.notes = notes;
    node.setAttribute('notes', notes);
  }


  void saveToFile() {
    file?.writeAsStringSync(xmlDoc.toString());
  }

  static Future<OPAFProject> parse(String path) async {
    File file = File(path);
    var doc = XmlDocument.parse(await file.readAsString());

    return parseDoc(doc, file: file);
  }

  static Future<OPAFProject> parseDoc(XmlDocument doc, {File? file}) async {
    var node = doc.rootElement;

    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.localName != 'project') {
      throw OPAFParserException("Expected node with name 'project' and got '${node.name}'");
    }
  
    if (node.getAttribute('name') == null) {
      throw OPAFParserException("Name attribute not found for project");
    }

    if (node.getAttribute('unique_id') == null) {
      throw OPAFParserException("Unique ID not defined for project");
    }
  
    String name = node.getAttribute("name") as String;
    String uniqueId = node.getAttribute("unique_id") as String;

    // Spec Version
    Version? specVersion = Version.parse(node.getAttribute("spec_version") ?? supportedSpec.toString());

    // Progress
    int? progress = int.tryParse(node.getAttribute("progress") ?? '0');

    // Notes
    String notes = node.getAttribute("notes") ?? '';
    
    return OPAFProject(file, doc, name, uniqueId, specVersion, progress ?? 0, notes);
  }
}