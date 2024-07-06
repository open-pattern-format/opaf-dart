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

import 'package:opaf/src/metadata/needle.dart';
import 'package:xml/xml.dart';

import 'opaf_exceptions.dart';

import 'metadata/designer.dart';
import 'metadata/gauge.dart';
import 'metadata/image.dart';
import 'metadata/notion.dart';
import 'metadata/note.dart';
import 'metadata/schematic.dart';
import 'metadata/size.dart';
import 'metadata/technique.dart';
import 'metadata/utils.dart';
import 'metadata/yarn.dart';

class OPAFMetadata {
  String? title = '';
  String? copyright = '';
  String? description;
  String? published;
  List<String> tags = [];
  List<MetadataImage> images = [];
  List<Notion> notions = [];
  List<Needle> needles = [];
  List<Designer> designers = [];
  List<Size> sizes = [];
  List<Technique> techniques = [];
  List<Schematic> schematics = [];
  List<Gauge> gauges = [];
  List<Yarn> yarns = [];
  List<Note> notes = [];

  OPAFMetadata();

  void toXml(XmlBuilder builder) {
    if (title != null) {
      builder.element("title", nest:() {
        builder.text(title as String);
      });
    }
  
    if (copyright != null) {
      builder.element("copyright", nest:() {
        builder.text(copyright as String);
      });
    }
  
    if (description != null) {
      builder.element("description", nest:() {
        builder.text(description as String);
      });
    }

    if (published != null) {
      builder.element("published", nest:() {
        builder.text(published as String);
      });
    }

    for (var t in tags) {
      builder.element("tag", nest:() {
        builder.text(t);
      });
    }

    for (var n in notions) {
      n.toXml(builder);
    }

    for (var n in needles) {
      n.toXml(builder);
    }

    for (var i in images) {
      i.toXml(builder);
    }

    for (var s in sizes) {
      s.toXml(builder);
    }

    for (var d in designers) {
      d.toXml(builder);
    }

    for (var t in techniques) {
      t.toXml(builder);
    }

    for (var g in gauges) {
      g.toXml(builder);
    }

    for (var s in schematics) {
      s.toXml(builder);
    }

    for(var y in yarns) {
      y.toXml(builder);
    }

    for (var n in notes) {
      n.toXml(builder);
    }
  }

  static OPAFMetadata parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'metadata') {
      print("Expected node with name 'metadata' and got '${node.name}'");
      throw OPAFParserException();
    }

    // Check metadata
    MetadataUtils.checkNode(node);

    var metadata = OPAFMetadata();

    for (var e in node.childElements) {
      // Title
      if (e.localName == 'title') {
        metadata.title = e.innerText;
      }

      // Description
      if (e.localName == 'description') {
        metadata.description = e.innerText;
      }

      // Published
      if (e.localName == 'published') {
        metadata.published= e.innerText;
      }

      // Copyright
      if (e.localName == 'copyright') {
        metadata.copyright = e.innerText;
      }

      // Image
      if (e.localName == 'image') {
        metadata.images.add(MetadataImage.parse(e));
      }

      // Tag
      if (e.localName == 'tag') {
        metadata.tags.add(e.innerText);
      }

      // Designer
      if (e.localName == 'designer') {
        metadata.designers.add(Designer.parse(e));
      }

      // Size
      if (e.localName == 'size') {
        metadata.sizes.add(Size.parse(e));
      }

      // Technique
      if (e.localName == 'technique') {
        metadata.techniques.add(Technique.parse(e));
      }

      // Schematic
      if (e.localName == 'schematic') {
        metadata.schematics.add(Schematic.parse(e));
      }

      // Gauge
      if (e.localName == 'gauge') {
        metadata.gauges.add(Gauge.parse(e));
      }

      // Yarn
      if (e.localName == 'yarn') {
        metadata.yarns.add(Yarn.parse(e));
      }

      // Notion
      if (e.localName == 'notion') {
        metadata.notions.add(Notion.parse(e));
      }

      // Needles
      if (e.localName == 'needle') {
        metadata.needles.add(Needle.parse(e));
      }

      // Note
      if (e.localName == 'note') {
        metadata.notes.add(Note.parse(e));
      }
    }

    return metadata;
  }
}