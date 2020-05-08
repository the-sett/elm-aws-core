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

AWS SDK for elm.

The elm-aws-core package provides functions and types that facilitate making
HTTP requests to AWS services. Use it to create user-friendly clients to
specific AWS services.


## Modules in this package

  - [AWS.Core.Service](AWS-Core-Service): Create a service definition. Every service client should define its own `Service` definition.
  - [AWS.Core.Credentials](AWS-Core-Credentials): Create AWS credentials used to sign requests.
  - [AWS.Core.Http](AWS-Core-Http): Create requests, sign, and send them. Signing and sending a request requires both a `Service` and `Credentials`.
  - [AWS.Core.Enum](AWS-Core-Enum): Many AWS services define enumerations. This small module provides functions to convert from Elm types to string values.


## Usage example

    import AWS.Core.Credentials as Credentials
    import AWS.Core.Http as Http exposing (Method(..))
    import AWS.Core.Service as Service
    import Json.Decode
    import Task

    let
        creds =
            Credentials.fromAccessKeys
                "ACCESS KEY ID"
                "SECRET ACCESS KEY"
        service =
            Service.defineGlobal
                "sts"
                "2011-06-15"
                Service.query
                Service.signV4
                (Service.setXmlNamespace "https://sts.amazonaws.com/doc/2011-06-15/")
        handler =
            \result ->
                case result of
                    Ok someValue ->
                        -- someValue is what you get from the decoder
                        -- that is provided to the request call below.
                        -- In this case, it would be an Int because
                        -- we are using Json.Decode.int as the decoder.
                        someValue /= -1
                    Err err ->
                        -- err is an Http.Error
                        -- See: http://package.elm-lang.org/packages/elm-lang/http/latest/Http#Error
                        False
    in
    Http.request
        GET
        "/some/path"
        Http.emptyBody
        Json.Decode.int
        |> Http.send service creds
        |> Task.attempt handler
        |> (/=) Cmd.none
    --> True
