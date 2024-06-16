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
  Uint8List? data;
  String? uri;
  int? size;
  String? path;

  OPAFImage(this.name, this.data, this.uri, this.size, this.path);

  convert() {
    if (path == null) {
      print("Image path not found.");
      throw OPAFParserException();
    }

    // Decode image
    Image? origImage = decodeImage(File(path!).readAsBytesSync());

    if (origImage == null) {
      print("Failed to decode image at path '$path'");
      throw OPAFParserException();
    }

    // Resize
    int scale = size ?? OPAFImage.defaultSize;

    final image = copyResize(origImage, width: scale, maintainAspect: true);

    data = encodeJpg(image, quality: 80);
    uri = null;
    size = null;
  }

  static OPAFImage parse(XmlElement node, String? dir) {
    Uint8List? data;
    String? path;
    String? uri;
    int? size;

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
      uri = node.getAttribute("uri") as String;
      path = OPAFUtils.parseUri(uri, dir);

      if (path == null) {
        print("Image not found with uri: $uri");
        throw OPAFParserException();
      }
    }

    // Data
    if (node.getAttribute('data') != null) {
      data = base64Decode(node.getAttribute("data") as String);
    }

    // Size
    if (node.getAttribute('size') != null) {
      size = int.tryParse(node.getAttribute('size') as String) ?? OPAFImage.defaultSize;
    }
    
    String name = node.getAttribute("name") as String;
    
    return OPAFImage(name, data, uri, size, path);
  }
}