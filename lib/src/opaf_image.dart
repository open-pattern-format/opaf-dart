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
      throw OPAFParserException("Image path not found");
    }

    // Decode image
    Image? image = decodeImage(File(path!).readAsBytesSync());

    if (image == null) {
      throw OPAFParserException("Failed to decode image at path '$path'");
    }

    // Resize
    int scale = size ?? OPAFImage.defaultSize;

    if (image.height > scale || image.width > scale) {
      if (image.height >= image.width) {
        image = copyResize(image, height: scale, maintainAspect: true);
      } else {
        image = copyResize(image, width: scale, maintainAspect: true);
      }
    }

    if (image.hasAlpha) {
      data = encodePng(image, level: 6);
    } else {
      data = encodeJpg(image, quality: 75);
    }
  }

  static OPAFImage parse(XmlElement node, String? dir) {
    Uint8List? data;
    String? path;
    String? uri;
    int? size;

    if (node.nodeType != XmlNodeType.ELEMENT) {
      throw OPAFParserException("Unexpected node type");
    }
  
    if (!node.name.local.contains('image')) {
      throw OPAFParserException("Expected node with name 'opaf:define_image' or 'image' and got '${node.name}'");
    }
  
    if (node.getAttribute('name') == null) {
      throw OPAFParserException("Name attribute not found for image");
    }

    // URI
    if (node.getAttribute("uri") != null) {
      uri = node.getAttribute("uri") as String;
      path = OPAFUtils.parseUri(uri, dir);

      if (path == null) {
        throw OPAFParserException("Image not found with uri: $uri");
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