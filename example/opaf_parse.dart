import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:opaf/src/opaf_document.dart';

import 'package:opaf/src/opaf_parser.dart';

final args.ArgParser argumentParser = args.ArgParser()
  ..addOption(
    'input',
    abbr: 'i',
    help: 'Pattern file path',
  );

void printUsage() {
  stdout.writeln('Usage: opaf_parse [options]');
  stdout.writeln();
  stdout.writeln(argumentParser.usage);
  exit(1);
}

void main(List<String> arguments) {
  final results = argumentParser.parse(arguments);
  final input = results['input'];

  if (input == null) {
    printUsage();
  }

  OPAFParser parser = OPAFParser.fromFile(input, OPAFDocument());

  try {
    parser.initialize();
    parser.parse();
  } on Exception catch (e, s) {
    print("$e: $s");
    return;
  }

  print("Successfully parsed pattern file");
}