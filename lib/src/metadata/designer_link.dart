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

import 'package:string_validator/string_validator.dart';
import 'package:xml/xml.dart';

import '../opaf_exceptions.dart';

class DesignerLink {
  String name;
  String url;

  DesignerLink(this.name, this.url);

  void toXml(XmlBuilder builder) {
    builder.element("link", nest:() {
      builder.attribute("name", name);
      builder.attribute("url", url);
    });
  }

  static DesignerLink parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'link') {
      print("Expected node with name 'link' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.getAttribute('name') == null) {
      print("Attribute 'name' missing from designer link");
      throw OPAFParserException();
    }
  
    if (node.getAttribute('url') == null) {
      print("Attribute 'url' missing from designer link");
      throw OPAFParserException();
    }

    String name = node.getAttribute('name') as String;
    String url = node.getAttribute('url') as String;

    if (!isURL(url)) {
      print("${url} is not a valid url");
      throw OPAFParserException();
    }

    DesignerLink link = DesignerLink(name, url);

    return link;
  }
}