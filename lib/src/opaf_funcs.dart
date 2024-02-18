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

import 'opaf_exceptions.dart';

class OPAFFuncs {

  static int round(num val) {
    return val.round();
  }

  static num mround(num val, num? multiple) {
    multiple = multiple ?? 1;
    return multiple * (val / multiple).round();
  }

  static num floor(num val, [num? multiple]) {
    multiple = multiple ?? 1;
    return multiple * (val / multiple).floor();
  }

  static num ceil(num val, [num? multiple]) {
    multiple = multiple ?? 1;
    return multiple * (val / multiple).ceil();
  }

  static bool less(num val, num test) {
    return val < test;
  }

  static bool greater(num val, num test) {
    return val > test;
  }

  static num abs(num val) {
    return val.abs();
  }

  static bool equals(dynamic val, dynamic values) {
    if (values is List) {
      for (var v in values) {
        if (val == v) {
          return true;
        }
      }
    }

    return val == values;
  }

  static bool notEquals(dynamic val, dynamic values) {
    return !equals(val, values);
  }

  static bool and(dynamic val1, dynamic val2) {
    return val1 && val2;
  }

  static bool or(dynamic val1, dynamic val2) {
    return val1 || val2;
  }

  static bool not(dynamic val) {
    return !val;
  }

  static dynamic choose(int index, dynamic values) {
    if (index < 1) {
      print("Index must be 1 or greater for 'CHOOSE' function");
      throw OPAFException();
    }

    if (values.length < index) {
      print("Index $index is out of range. Expected an index between 1 and ${values.length}");
      throw OPAFException();
    }

    return values[index - 1];
  }

  static dynamic loopChoose(int index, dynamic values) {
    if (index < 1) {
      print("Index must be 1 or greater for 'CHOOSE' function");
      throw OPAFException();
    }

    // Loop index
    index = (index % values.length).round();

    if (index == 0) {
      index = values.length;
    }

    return values[index - 1];
  }

  static bool isEmpty(dynamic val) {
    return val.toString().isEmpty;
  }
}

