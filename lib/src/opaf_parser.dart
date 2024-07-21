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

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';
import 'package:version/version.dart';

import 'opaf_action.dart';
import 'opaf_block.dart';
import 'opaf_color.dart';
import 'opaf_component.dart';
import 'opaf_chart.dart';
import 'opaf_config.dart';
import 'opaf_document.dart';
import 'opaf_exceptions.dart';
import 'opaf_image.dart';
import 'opaf_metadata.dart';
import 'opaf_utils.dart';
import 'opaf_value.dart';

class OPAFParser {
  late String filePath;
  late XmlDocument xmlDoc;
  late OPAFDocument opafDoc;

  OPAFParser.update(this.xmlDoc, this.opafDoc);

  OPAFParser(this.filePath) {
    opafDoc = OPAFDocument(File(filePath));
  }

  OPAFParser initialize() {
    xmlDoc = XmlDocument.parse(File(filePath).readAsStringSync());

    if (xmlDoc.rootElement.name.local != 'pattern') {
      throw OPAFParserException("'pattern' root node not found in OPAF file");
    }

    if (xmlDoc.rootElement.getAttribute('xmlns:opaf') == null) {
      throw OPAFParserException('OPAF namespace is not declared in pattern attributes');
    }

    if (xmlDoc.rootElement.getAttribute('name') == null) {
      throw OPAFParserException("Pattern file is missing mandatory 'name' attribute");
    }
  
    return this;
  }

  OPAFDocument finish() {
    return opafDoc;
  }

  OPAFParser parseRoot() {
    opafDoc.name = xmlDoc.rootElement.getAttribute('name') as String;

    if (xmlDoc.rootElement.getAttribute('version') != null) {
      opafDoc.version = Version.parse(xmlDoc.rootElement.getAttribute('version') as String);
    }

    if (xmlDoc.rootElement.getAttribute('pkg_version') != null) {
      opafDoc.pkgVersion = Version.parse(xmlDoc.rootElement.getAttribute('pkg_version') as String);
    }

    if (xmlDoc.rootElement.getAttribute('unique_id') != null) {
      opafDoc.uniqueId = xmlDoc.rootElement.getAttribute('unique_id') as String;
    }

    return this;
  }

  OPAFParser parseOpafColors([XmlDocument? doc]) {
    XmlElement root = doc == null ? xmlDoc.rootElement : doc.rootElement;
    var elements = root.findElements('opaf:define_color');

    for (var element in elements) {
      var color = OPAFColor.parse(element);
      opafDoc.addOpafColor(color);
    }

    return this;
  }

  OPAFParser parseOpafConfigs([XmlDocument? doc]) {
    XmlElement root = doc == null ? xmlDoc.rootElement : doc.rootElement;
    var elements = root.findElements('opaf:define_config');

    for (var element in elements) {
      var config = OPAFConfig.parse(element);
      opafDoc.addOpafConfig(config);
    }

    return this;
  }

  OPAFParser parseOpafValues([XmlDocument? doc]) {
    XmlElement root = doc == null ? xmlDoc.rootElement : doc.rootElement;
    var elements = root.findElements('opaf:define_value');

    for (var element in elements) {
      var value = OPAFValue.parse(element);
      opafDoc.addOpafValue(value);
    }

    return this;
  }

  OPAFParser parseOpafImages([String? dir, XmlDocument? doc]) {
    XmlElement root = doc == null ? xmlDoc.rootElement : doc.rootElement;
    var elements = root.findElements('opaf:define_image');

    for (var element in elements) {
      var image = OPAFImage.parse(element, dir ?? p.dirname(filePath));
      opafDoc.addOpafImage(image);
    }

    return this;
  }

  OPAFParser parseOpafMetadata([XmlDocument? doc]) {
    XmlElement root = doc == null ? xmlDoc.rootElement : doc.rootElement;
    var elements = root.findElements('opaf:metadata');
    
    if (elements.isNotEmpty) {
      opafDoc.setOpafMetadata(OPAFMetadata.parse(elements.first));
    }

    return this;
  }

  OPAFParser parseOpafActions([XmlDocument? doc]) {
    XmlElement root = doc == null ? xmlDoc.rootElement : doc.rootElement;
    var elements = root.findElements('opaf:define_action');

    for (var element in elements) {
      var action = OPAFAction.parse(element);
      opafDoc.addOpafAction(action);
    }

    return this;
  }

  OPAFParser parseOpafCharts([XmlDocument? doc]) {
    XmlElement root = doc == null ? xmlDoc.rootElement : doc.rootElement;
    var elements = root.findElements('opaf:define_chart');

    for (var element in elements) {
      var chart = OPAFChart.parse(element);
      opafDoc.addOpafChart(chart);
    }

    return this;
  }

  OPAFParser parseOpafBlocks([XmlDocument? doc]) {
    XmlElement root = doc == null ? xmlDoc.rootElement : doc.rootElement;
    var elements = root.findElements('opaf:define_block');

    for (var element in elements) {
      var block = OPAFBlock.parse(element);
      opafDoc.addOpafBlock(block);
    }

    return this;
  }

  OPAFParser parseOpafComponents() {
    var elements = xmlDoc.rootElement.findElements('opaf:component');

    print(elements.length.toString());

    for (var element in elements) {
      var component = OPAFComponent.parse(element);
      opafDoc.addOpafComponent(component);
    }

    print(opafDoc.opafComponents.length.toString());

    return this;
  }

  void parseOpafIncludes([String? dir, XmlDocument? doc]) {
    XmlElement root = doc == null ? xmlDoc.rootElement : doc.rootElement;
    var elements = root.findElements('opaf:include');

    for (var element in elements) {
      String? uri = element.getAttribute("uri");

      if (uri == null) {
        print("Include is missing 'uri' attribute: ${element.toString()}");
        continue;
      }
      
      String? path = OPAFUtils.parseUri(uri, dir ?? p.dirname(filePath));

      if (path == null) {
        throw OPAFParserException("Failed to find included file with uri: $uri");
      }

      // Recursively parse included files
      XmlDocument incDoc = XmlDocument.parse(File(path).readAsStringSync());
      parseOpafIncludes(p.dirname(path), incDoc);
      parseOpafColors(incDoc);
      parseOpafConfigs(incDoc);
      parseOpafValues(incDoc);
      parseOpafImages(p.dirname(path), incDoc);
      parseOpafMetadata(incDoc);
      parseOpafActions(incDoc);
      parseOpafCharts(incDoc);
      parseOpafBlocks(incDoc);
    }
  }

  OPAFDocument parse() {
    parseRoot();
    parseOpafIncludes();
    parseOpafColors();
    parseOpafConfigs();
    parseOpafValues();
    parseOpafImages();
    parseOpafMetadata();
    parseOpafActions();
    parseOpafCharts();
    parseOpafBlocks();
    parseOpafComponents();
    
    return opafDoc;
  }
}