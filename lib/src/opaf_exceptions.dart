class OPAFException implements Exception {
  const OPAFException() : super();
}

class OPAFInvalidException implements OPAFException {
  const OPAFInvalidException() : super();
}

class OPAFParserException implements OPAFException {
  const OPAFParserException() : super();
}

class OPAFNotPackagedException implements OPAFException {
  const OPAFNotPackagedException() : super();
}

class OPAFNotDefinedException implements OPAFException {
  const OPAFNotDefinedException() : super();
}