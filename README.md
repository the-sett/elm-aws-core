**Contacts for Support**
- @rupertlssmith on https://elmlang.slack.com
- @rupert on https://discourse.elm-lang.org

**Status** - 08-May-2020 - Published as version 6.0.0

The API has been redesigned. The intermediate `.Core.` module name has been
removed. The old `Encode` and `Decode` modules were dropped as not very useful
and poorly designed.

A new `KVEncode` module has been introduced to help with building headers and
query parameters.

AWS URI encoding was taken from the old `Encode` module and put in the `HTTP`
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


## Usage example

    import AWS.Credentials as Credentials
    import AWS.Http as Http exposing (Method(..))
    import AWS.Service as Service
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
