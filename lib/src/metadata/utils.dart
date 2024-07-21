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

import 'package:xml/xml.dart';

import '../opaf_exceptions.dart';
import '../opaf_metadata.dart';
import 'note.dart';

class MetadataUtils {

  static final supportedNodes = [
      'color',
      'copyright',
      'description',
      'designer',
      'element',
      'gauge',
      'image',
      'link',
      'measurement',
      'needles',
      'note',
      'notion',
      'published',
      'title',
      'schematic',
      'size',
      'table',
      'tag',
      'technique',
      'yarn'
  ];

  static final textNodes = [
      'copyright',
      'description',
      'published',
      'tag',
      'title'
  ];

  static XmlNode checkNode(XmlElement node) {
    if (node.childElements.isEmpty) {
        return node;
    }

    for (var child in node.childElements) {
      if (child.nodeType != XmlNodeType.ELEMENT) {
          child.remove();
          continue;
      }

      if (!supportedNodes.contains(child.name.local)) {
          throw OPAFParserException("Node with name '${child.name.local}' not recognized");
      }

      if (textNodes.contains(child.name.local)) {
          continue;
      }

      if (child.childElements.isNotEmpty) {
          checkNode(child);
      }
    }

    return node;
  }

  static List<Note> getNotesByTag(OPAFMetadata metadata, String tag) {
    List<Note> notes = [];

    for (var n in metadata.notes) {
      if (n.tag == null) {
        if (tag.isEmpty) {
          notes.add(n);
        } else {
          continue;
        }
      }

      if (n.tag == tag) {
        notes.add(n);
      }
    }

    return notes;
  }
}