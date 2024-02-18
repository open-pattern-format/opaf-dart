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

