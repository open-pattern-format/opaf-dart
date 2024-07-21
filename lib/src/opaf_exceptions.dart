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

class OPAFException implements Exception {
  String error;
  OPAFException(this.error) : super();
}

class OPAFInvalidException implements OPAFException {
  @override
  String error;

  OPAFInvalidException(this.error) : super();
}

class OPAFParserException implements OPAFException {
  @override
  String error;

  OPAFParserException(this.error) : super();
}

class OPAFNotPackagedException implements OPAFException {
  @override
  String error;

  OPAFNotPackagedException(this.error) : super();
}

class OPAFNotDefinedException implements OPAFException {
  @override
  String error;

  OPAFNotDefinedException(this.error) : super();
}

class OPAFInvalidConditionException implements OPAFException {
  @override
  String error;

  OPAFInvalidConditionException(this.error) : super();
}