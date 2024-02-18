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