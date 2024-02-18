import 'package:string_validator/string_validator.dart';
import 'package:xml/xml.dart';

import '../opaf_exceptions.dart';
import 'image.dart';

class Designer {
  String name;
  String? email;
  String? about;
  List<Image> images = [];
  Map<String, String> links = {};

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

      for (var l in links.keys) {
        builder.element("link", attributes: {"name": l, "url": links[l] as String});
      }
    });
  }

  static Designer parse(XmlElement node) {
    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (node.name.local != 'designer') {
      print("Expected node with name 'designer' and got '${node.name}'");
      throw OPAFParserException();
    }

    if (node.getAttribute('name') == null) {
      print("Attribute 'name' missing from designer element");
      throw OPAFParserException();
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
        designer.images.add(Image.parse(e));
      }

      if (e.name.local == 'link') {
        var lName = e.getAttribute('name');
        var lUrl = e.getAttribute('url');

        if (lName == null || lUrl == null) {
          continue;
        }

        if (isURL(lUrl)) {
          designer.links[lName] = lUrl;
        }
      }
    }

    return designer;
  }
}