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

import 'dart:math' as m;

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
    // Do string comparisons in lower case
    if (val is String) {
      val = val.toLowerCase();
    }

    if (values is String) {
      values = values.toLowerCase();
    }

    if (values is List) {
      for (var v in values) {
        if (v is String) {
          v = v.toLowerCase();
        }

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
      throw OPAFException("Index must be 1 or greater for 'CHOOSE' function");
    }

    if (values.length < index) {
      throw OPAFException("Index $index is out of range. Expected an index between 1 and ${values.length}");
    }

    return values[index - 1];
  }

  static bool isEmpty(dynamic val) {
    if (val == null) {
      return true;
    }

    return val.toString().isEmpty;
  }

  static bool odd(num val) {
    return !even(val);
  }

  static bool even(num val) {
    return (val % 2) == 0;
  }

  static bool multiple(num val, num multiple) {
    return (val % multiple) == 0;
  }

  static num min(num val1, num val2) {
    return m.min(val1, val2);
  }

  static num max(num val1, num val2) {
    return m.max(val1, val2);
  }

  static bool toBool(dynamic val) {
    if (val is bool) {
      return val;
    }

    if (val is String) {
      return ['true', 'yes', '1'].contains(val.trim().toLowerCase());
    }

    return val == 1;
  }

  static dynamic ifElse(bool test, dynamic valT, dynamic valF) {
    if (test) {
      return valT;
    }

    return valF;
  }

  static num mod(num val, num div) {
    return val % div;
  }

  static String rept(dynamic str, int num, String sep) {
    if (num <= 0) {
      return '';
    }

    if (num == 1) {
      return str.toString();
    }

    String result = '';

    for (var i = 0; i < num; i++) {
      result += str.toString();

      if (i < (num - 1)) {
        result += sep;
      }
    }

    return result;
  }
}