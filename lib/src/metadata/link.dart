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

class Link {
  String name;
  String url;

  Link(this.name, this.url);

  void toXml(XmlBuilder builder) {
    builder.element("link", nest:() {
      builder.attribute("name", name);
      builder.attribute("url", url);
    });
  }

  static Link parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'link') {
      throw OPAFParserException("Expected node with name 'link' and got '${node.name}'");
    }

    if (node.getAttribute('name') == null) {
      throw OPAFParserException("Attribute 'name' missing from designer link");
    }
  
    if (node.getAttribute('url') == null) {
      throw OPAFParserException("Attribute 'url' missing from designer link");
    }

    String name = node.getAttribute('name') as String;
    String url = node.getAttribute('url') as String;

    if (!isURL(url)) {
      throw OPAFParserException("$url is not a valid url");
    }

    Link link = Link(name, url);

    return link;
  }
}