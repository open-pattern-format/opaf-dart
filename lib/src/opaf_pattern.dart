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

import 'package:version/version.dart';
import 'package:xml/xml.dart';

import 'opaf_exceptions.dart';
import 'opaf_metadata.dart';


class OPAFPattern {
  String uniqueId;
  String name;
  Version version;
  OPAFMetadata metadata = OPAFMetadata();
  
  OPAFPattern(this.uniqueId, this.name, this.version);

  String getTitle() {
    if (metadata.title == null) {
      return name;
    }

    return metadata.title as String;
  }

  static OPAFPattern parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.localName != 'pattern') {
      print("Expected node with name 'pattern' and got '${node.name}'");
      throw OPAFParserException();
    }
  
    if (node.getAttribute('name') == null) {
      print("Name attribute not found for pattern");
      throw OPAFParserException();
    }

    if (node.getAttribute('unique_id') == null) {
      print("Unique ID not defined for pattern");
      throw OPAFParserException();
    }
  
    if (node.getAttribute('version') == null) {
      print("Version not defined for pattern");
      throw OPAFParserException();
    }
  
    String name = node.getAttribute("name") as String;
    String uniqueId = node.getAttribute("unique_id") as String;
    Version version = Version.parse(node.getAttribute('version') as String);
    
    var pattern = OPAFPattern(name, uniqueId, version);

    for (var c in node.childElements) {
      if (c.localName == 'metadata') {
        pattern.metadata = OPAFMetadata.parse(c);
      }
    }

    return pattern;
  }
}