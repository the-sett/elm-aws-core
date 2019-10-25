** Status ** - 25-Oct-2019 - Published as version 1.2.0. This is the code ported to Elm 0.19 from the
original work by KTonon. It is untested, and the code generator for the service stubs is still being
worked on. Therefore this should be considered a work in progress and not ready for use.

# elm-aws-core

This package provides the functionality needed to make HTTP requests to AWS services.

All AWS service calls must be signed correctly, in order to pass on the authorized credentials of the
caller to the service. AWS has multiple signing schemes that different services use, specifically 'S3'
and 'V4'.

The AWS service portfolio is large with variations in signing schemes, AWS regions and service protocols
accross it. The aim of this package is to provide functions to sign HTTP requests correctly for all of
the services available on AWS. The specific service interface can then be implemented with this package
as a foundational element.
