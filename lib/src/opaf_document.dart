import 'dart:io';

import 'package:xml/xml.dart';
import 'package:version/version.dart';

import 'opaf_action.dart';
import 'opaf_block.dart';
import 'opaf_chart.dart';
import 'opaf_color.dart';
import 'opaf_component.dart';
import 'opaf_exceptions.dart';
import 'opaf_image.dart';
import 'opaf_metadata.dart';
import 'opaf_utils.dart';
import 'opaf_value.dart';

class OPAFDocument {
  File file;
  String uniqueId = "";
  String name = "";
  Version version = Version.parse('1.0');
  String? opafNamespace;
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
      if (opafNamespace != null) {
        builder.namespace(opafNamespace as String, 'opaf');
      }

      builder.attribute('name', name);
      builder.attribute('version', version.toString());

      if (uniqueId.isNotEmpty) {
        builder.attribute('unique_id', uniqueId);
      }

      if (pkgVersion != null) {
        builder.attribute('pkg_version', pkgVersion.toString());
      }
  
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

  void addOpafColor(OPAFColor color) {
    for (var c in opafColors) {
      if (c.name == color.name) {
        print("Color with name '${color.name}' already exists");
        throw OPAFInvalidException();
      }
    }
    opafColors.add(color);
  }

  void addOpafValue(OPAFValue value) {
    opafValues.add(value);
  }

  void addOpafImage(OPAFImage image) {
    for (var i in opafImages) {
      if (i.name == image.name) {
        print("Image with name '${image.name}' already exists");
        throw OPAFInvalidException();
      }
    }
    opafImages.add(image);
  }

 void addOpafAction(OPAFAction action) {
    for (var a in opafActions) {
      if (a.name == action.name) {
        print("Action with name '${action.name}' already exists");
        throw OPAFInvalidException();
      }
    }
    opafActions.add(action);
  }

 void addOpafChart(OPAFChart chart) {
    for (var c in opafCharts) {
      if (c.name == chart.name) {
        print("Chart with name '${chart.name}' already exists");
        throw OPAFInvalidException();
      }
    }
    opafCharts.add(chart);
  }

 void addOpafBlock(OPAFBlock block) {
    for (var b in opafBlocks) {
      if (b.name == block.name) {
        print("Block with name '${block.name}' already exists");
        throw OPAFInvalidException();
      }
    }
    opafBlocks.add(block);
  }

 void addOpafComponent(OPAFComponent component) {
    opafComponents.add(component);
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