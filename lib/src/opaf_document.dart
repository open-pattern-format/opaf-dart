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

import 'package:xml/xml.dart';
import 'package:version/version.dart';

import 'opaf_action.dart';
import 'opaf_block.dart';
import 'opaf_chart.dart';
import 'opaf_color.dart';
import 'opaf_component.dart';
import 'opaf_image.dart';
import 'opaf_metadata.dart';
import 'opaf_utils.dart';
import 'opaf_value.dart';

class OPAFDocument {
  File file;
  String uniqueId = "";
  String name = "";
  Version version = Version.parse('1.0');
  String opafNamespace = 'https://github.com/open-pattern-format/opaf/wiki';
  Version? pkgVersion;
  List<OPAFValue> opafValues = [];
  List<OPAFColor> opafColors = [];
  List<OPAFImage> opafImages = [];
  List<OPAFChart> opafCharts = [];
  List<OPAFBlock> opafBlocks = [];
  List<OPAFAction> opafActions = [];
  List<OPAFComponent> opafComponents = [];
  OPAFMetadata metadata = OPAFMetadata();
  
  OPAFDocument(this.file);

  XmlDocument toXml() {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('pattern', nest: () {
      builder.attribute('version', version.toString());
      builder.namespace(opafNamespace as String, 'opaf');

      if (name.isNotEmpty) {
        builder.attribute('name', name);
      }

      if (uniqueId.isNotEmpty) {
        builder.attribute('unique_id', uniqueId);
      }

      if (pkgVersion != null) {
        builder.attribute('pkg_version', pkgVersion.toString());
      }

      // Metadata
      builder.element('opaf:metadata', nest: () {
        metadata.toXml(builder);
      });

      // Colors
      for (var c in opafColors) {
        builder.element('opaf:define_color', nest: () {
          builder.attribute('name', c.name);
          builder.attribute('value', c.value);
        });
      }

      // Actions
      for (var a in opafActions) {
        builder.element('opaf:define_action', nest: () {
          builder.attribute('name', a.name);
          
          if (a.params.isNotEmpty) {
            builder.attribute('params', OPAFUtils.paramsToString(a.params));
          }

          for (var e in a.elements) {
            builder.xml(e);
          }
        });
      }

      // Values
      for (var v in opafValues) {
        builder.element('opaf:define_value', nest: () {
          builder.attribute('name', v.name);
          builder.attribute('value', v.value);
          builder.attribute('config', v.config);

          if (v.allowedValues.isNotEmpty) {
            builder.attribute('allowed_values', v.allowedValues.join(','));
          }

          if (v.description != null) {
            builder.attribute('description', v.description);
          }

          if (v.condition != null) {
            builder.attribute('condition', v.condition);
          }
        });
      }

      // Images
      for (var i in opafImages) {
        if (i.uri == null) {
            continue;
        }

        builder.element('opaf:define_image', nest: () {
          builder.attribute('name', i.name);
          builder.attribute('uri', i.uri);

          if (i.size != null) {
            builder.attribute('size', i.size.toString());
          }
        });
      }

      // Charts
      for (var c in opafCharts) {
        builder.element('opaf:define_chart', nest: () {
          builder.attribute('name', c.name);

          for (var r in c.rows) {
            builder.xml(r);
          }
        });
      }

      // Blocks
      for (var b in opafBlocks) {
        builder.element('opaf:define_block', nest: () {
          builder.attribute('name', b.name);
          
          if (b.params.isNotEmpty) {
            builder.attribute('params', OPAFUtils.paramsToString(b.params));
          }

          for (var e in b.elements) {
            builder.xml(e);
          }
        });
      }

      // Components
      for (var c in opafComponents) {
        builder.element('opaf:component', nest: () {
          builder.attribute('name', c.name);
          
          if (c.uniqueId.isNotEmpty) {
            builder.attribute('unique_id', uniqueId);
          }

          if (c.condition != null) {
            builder.attribute('condition', c.condition);
          }

          for (var e in c.elements) {
            builder.xml(e);
          }
        });
      }
    });

    return builder.buildDocument();
  }

  void saveToFile() {
    file.writeAsString(toXml().toString());
  }

  void addOpafColor(OPAFColor color) {
    int index = opafColors.indexWhere((c) => color.name == c.name);

    if (index < 0) {
      opafColors.add(color);
    } else {
      opafColors[index] = color;
    }
  }

  void addOpafValue(OPAFValue value) {
    int index = opafValues.indexWhere((v) => value.uniqueId == v.uniqueId);

    if (index < 0) {
      opafValues.add(value);
    } else {
      opafValues[index] = value;
    }
  }

  void addOpafImage(OPAFImage image) {
    int index = opafImages.indexWhere((i) => image.name == i.name);

    if (index < 0) {
      opafImages.add(image);
    } else {
      opafImages[index] = image;
    }
  }

 void addOpafAction(OPAFAction action) {
    int index = opafActions.indexWhere((a) => action.name == a.name);

    if (index < 0) {
      opafActions.add(action);
    } else {
      opafActions[index] = action;
    }
  }

 void addOpafChart(OPAFChart chart) {
    int index = opafCharts.indexWhere((c) => chart.name == c.name);

    if (index < 0) {
      opafCharts.add(chart);
    } else {
      opafCharts[index] = chart;
    }
  }

 void addOpafBlock(OPAFBlock block) {
    int index = opafBlocks.indexWhere((b) => block.name == b.name);

    if (index < 0) {
      opafBlocks.add(block);
    } else {
      opafBlocks[index] = block;
    }
  }

 void addOpafComponent(OPAFComponent component) {
    int index = opafComponents.indexWhere((c) => component.uniqueId == c.uniqueId);

    if (index < 0) {
      opafComponents.add(component);
    } else {
      opafComponents[index] = component;
    }
  }

  void setOpafMetadata(OPAFMetadata metadata) {
    this.metadata = metadata;
  }

  OPAFImage? getOpafImageByName(String name) {
    for (var i in opafImages) {
      if (i.name == name) {
        return i;
      }
    }

    return null;
  }

  OPAFImage? getOpafImageByTag(String tag) {
    if (opafImages.isEmpty || metadata.images.isEmpty) {
      return null;
    }

    // Find cover image
    for (var i in metadata.images) {
      if (i.tag != null) {
        if (i.tag == tag) {
          // Get image from doc
          var image = getOpafImageByName(i.name);

          if (image != null) {
            return image;
          }
        }
      }
    }

    return null;
  }

  Map<String, String> getOpafColors() {
    Map<String, String> colors = {};

    for (var c in opafColors) {
      colors[c.name] = c.value;
    }

    return colors;
  }

  OPAFAction? getOpafAction(String name) {
    for (var a in opafActions) {
      if (a.name == name) {
        return a;
      }
    }

    return null;
  }

  OPAFChart? getOpafChart(String name) {
    for (var c in opafCharts) {
      if (c.name == name) {
        return c;
      }
    }

    return null;
  }

  OPAFBlock? getOpafBlock(String name) {
    for (var b in opafBlocks) {
      if (b.name == name) {
        return b;
      }
    }

    return null;
  }

  String getTitle() {
    if (metadata.title == null) {
      return name;
    }

    return metadata.title as String;
  }

  List<OPAFValue> getConfigurableValues() {
    List<OPAFValue> values = [];

    for (var c in opafValues) {
      if (c.config) {
        values.add(c);
      }
    }

    return values;
  }
}