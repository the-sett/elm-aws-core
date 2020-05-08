**Contacts for Support**
- @rupertlssmith on https://elmlang.slack.com
- @rupert on https://discourse.elm-lang.org

**Status** - 08-May-2020 - Published as version 6.0.0

The API has been redesigned. The intermediate `.Core.` module name has been
removed. The old `Encode` and `Decode` modules were dropped as not very useful
and poorly designed.

A new `KVEncode` module has been introduced to help with building headers and
query parameters.

AWS URI encoding was taken from the old `Encode` module and put in its own `Uri`
module.

# elm-aws-core

This package provides the functionality needed to make HTTP requests to AWS
services.

All AWS service calls must be signed correctly, in order to pass on the
authorized credentials of the caller to the service. AWS has multiple signing
schemes that different services use, specifically 'S3' and 'V4'.

The AWS service portfolio is large with variations in signing schemes, AWS
regions and service protocols across it. The aim of this package is to provide
functions to build signed HTTP requests correctly for all of the services
available on AWS. The specific service interface can then be implemented with
this package as a foundational element.

## Modules in this package

  - [AWS.Service](AWS-Service): Build a service definition describing the
  protocol, signing scheme, base URL and so on for a service.
  - [AWS.Http](AWS-Http): Build requests, and sign and send them. Signing and
  sending a request requires both a `Service` and some `Credentials`.
  - [AWS.Credentials](AWS-Credentials): Create AWS credentials used to sign
  requests.
  - [AWS.KVEncode](AWS-KVEncode): Utility for helping to encode Elm data into
  key-valued string pairs, for setting query parameters or header fields.
  - [AWS.Uri](AWS-Uri): Utility for URI encoding specific to how AWS does it.
