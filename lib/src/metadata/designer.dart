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
import 'link.dart';
import 'image.dart';

class Designer {
  String name;
  String? email;
  String? about;
  List<MetadataImage> images = [];
  List<Link> links = [];

  Designer(this.name);

  void toXml(XmlBuilder builder) {
    builder.element("designer", nest:() {
      builder.attribute("name", name);
      
      if (email != null) {
        builder.attribute("email", email);
      }

      if (about != null) {
        builder.attribute("about", about);
      }

      for (var i in images) {
        i.toXml(builder);
      }

      for (var l in links) {
        l.toXml(builder);
      }
    });
  }

  static Designer parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (node.name.local != 'designer') {
      throw OPAFParserException("Expected node with name 'designer' and got '${node.name}'");
    }

    if (node.getAttribute('name') == null) {
      throw OPAFParserException("Attribute 'name' missing from designer element");
    }

    String name = node.getAttribute('name') as String;

    Designer designer = Designer(name);

    if (node.getAttribute('email') != null) {
      var email = node.getAttribute('email') as String;

      if (isEmail(email)) {
        designer.email = node.getAttribute('email');
      }
    }

    designer.about = node.getAttribute('about');

    for (var e in node.childElements) {
      if (e.name.local == 'image') {
        designer.images.add(MetadataImage.parse(e));
      }

      if (e.name.local == 'link') {
        designer.links.add(Link.parse(e));
      }
    }

    return designer;
  }
}