**Contacts for Support**
- @rupertlssmith on https://elmlang.slack.com
- @rupert on https://discourse.elm-lang.org

**Status** - 08-Mar-2019 - Published as version 4.0.0

Requests do not have to be build with JSON decoders, so it should be possible to
get the XML based services working now.

The code generator is capable of generating 'JSON' based services with the V4 signing scheme. The AWS Cognito service is being published based on this. This
is still a work in progress but is able to support a first set of AWS services.

# elm-aws-core

This package provides the functionality needed to make HTTP requests to AWS services.

All AWS service calls must be signed correctly, in order to pass on the authorized credentials of the
caller to the service. AWS has multiple signing schemes that different services use, specifically 'S3'
and 'V4'.

The AWS service portfolio is large with variations in signing schemes, AWS regions and service protocols
accross it. The aim of this package is to provide functions to sign HTTP requests correctly for all of
the services available on AWS. The specific service interface can then be implemented with this package
as a foundational element.
