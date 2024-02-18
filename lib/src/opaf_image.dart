import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:xml/xml.dart';

import 'opaf_exceptions.dart';
import 'opaf_utils.dart';


class OPAFImage {
  static const defaultSize = 1000;

  String name;
  Uint8List data;

  OPAFImage(this.name, this.data);

  static OPAFImage parse(XmlElement node, String? dir) {
    Uint8List data;

    if (node.nodeType != XmlNodeType.ELEMENT) {
      print("Unexpected node type");
      throw OPAFParserException();
    }
  
    if (!node.name.local.contains('image')) {
      print("Expected node with name 'opaf:define_image' or 'image' and got '${node.name}'");
      throw OPAFParserException();
    }
  
    if (node.getAttribute('name') == null) {
      print("Name attribute not found for image");
      throw OPAFParserException();
    }

    // URI
    if (node.getAttribute("uri") != null) {
      String uri = node.getAttribute("uri") as String;
      String? imgPath = OPAFUtils.parseUri(uri, dir);

      if (imgPath == null) {
        print("Image not found with uri: $uri");
        throw OPAFParserException();
      }

      // Decode image
      Image? origImage = decodeImage(File(imgPath).readAsBytesSync());

      if (origImage == null) {
        print("Failed to decode image at path '$imgPath'");
        throw OPAFParserException();
      }

      // Resize
      int size = OPAFImage.defaultSize;

      if (node.getAttribute('size') != null) {
        size = int.tryParse(node.getAttribute('size') as String) ?? OPAFImage.defaultSize;
      }

      final image = copyResize(origImage, width: size, maintainAspect: true);

      data = encodeJpg(image, quality: 80);
    } else {
      if (node.getAttribute('data') == null) {
        print("No 'data' attribute found for image");
        throw OPAFParserException();
      }

      data = base64Decode(node.getAttribute("data") as String);
    }
    
    String name = node.getAttribute("name") as String;
    
    return OPAFImage(name, data);
  }
}