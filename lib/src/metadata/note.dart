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

class Note {
  String text;
  String? tag;

  Note(this.text);

  void toXml(XmlBuilder builder) {
    builder.element("note", nest:() {
      builder.attribute("text", text);

      if (tag != null) {
        builder.attribute("tag", tag);
      }
    });
  }

  static Note parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'note') {
      throw OPAFParserException("Expected node with name 'note' and got '${node.name}'");
    }

    if (node.getAttribute('text') == null) {
      throw OPAFParserException("Attribute 'text' missing from 'note' element");
    }

    String text = node.getAttribute('text') as String;

    Note note = Note(text);
    note.tag = node.getAttribute('tag');

    return note;
  }
}