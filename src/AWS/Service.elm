module AWS.Service exposing
    ( Service, ApiVersion, Region, Protocol(..), Signer(..), TimestampFormat(..), Endpoint(..)
    , signerEnum, protocolEnum, timestampFormatEnum
    , defineGlobal, defineRegional
    , setJsonVersion, setSigningName, setTargetPrefix, setTimestampFormat, setXmlNamespace, toDigitalOceanSpaces
    , endpointPrefix, region, host, protocol, signer, targetPrefix, jsonContentType, acceptType
    )

{-| AWS service configuration.


# Table of Contents

  - [Types](#types)
  - [Constructors](#constructors)
  - [Property Setters](#property-setters)
  - [Protocols](#protocols)
  - [Signatures](#signatures)
  - [Timestamp Formats](#timestamp-formats)
  - [Attributes](#attributes)


# Types

@docs Service, ApiVersion, Region, Protocol, Signer, TimestampFormat, Endpoint
@docs signerEnum, protocolEnum, timestampFormatEnum


# Constructors

Use either one of these to create a service definition.

@docs defineGlobal, defineRegional


# Property Setters

@docs setJsonVersion, setSigningName, setTargetPrefix, setTimestampFormat, setXmlNamespace, toDigitalOceanSpaces


# Attributes

These functions are exposed so that [AWS.Http](AWS-Core-Http) can properly
sign requests. They can be useful for debugging, testing, and logging, but
otherwise are not required.

@docs endpointPrefix, region, host, protocol, signer, targetPrefix, jsonContentType, acceptType

-}

import Enum exposing (Enum)



-- SERVICES


{-| Defines an AWS service.
-}
type Service
    = Service
        { endpointPrefix : String
        , apiVersion : ApiVersion
        , protocol : Protocol
        , signer : Signer
        , jsonVersion : Maybe String
        , signingName : Maybe String
        , targetPrefix : String
        , timestampFormat : TimestampFormat
        , xmlNamespace : Maybe String
        , endpoint : Endpoint
        , hostResolver : Endpoint -> String -> String
        , regionResolver : Endpoint -> String
        }


{-| Version of a service.
-}
type alias ApiVersion =
    String


{-| Specifies JSON version.
-}
type alias JsonVersion =
    String


define :
    String
    -> ApiVersion
    -> Protocol
    -> Signer
    -> (Service -> Service)
    -> Service
define prefix apiVersion proto signerType extra =
    Service
        { endpointPrefix = prefix
        , protocol = proto
        , signer = signerType
        , apiVersion = apiVersion
        , jsonVersion = Nothing
        , signingName = Nothing
        , targetPrefix = defaultTargetPrefix prefix apiVersion
        , timestampFormat = defaultTimestampFormat proto
        , xmlNamespace = Nothing
        , endpoint = GlobalEndpoint
        , hostResolver = defaultHostResolver
        , regionResolver = defaultRegionResolver
        }
        |> extra


{-| Creates a global service definition.

    let
        service = defineGlobal "sts" "2011-06-15" query signV4
            (setXmlNamespace "https://sts.amazonaws.com/doc/2011-06-15/")
    in
    ( service |> endpointPrefix
    , service |> host
    , service |> targetPrefix
    )
    --> ( "sts"
    --> , "sts.amazonaws.com"
    --> , "AWSSTS_20110615"
    --> )

-}
defineGlobal :
    String
    -> ApiVersion
    -> Protocol
    -> Signer
    -> (Service -> Service)
    -> Service
defineGlobal =
    define


{-| Creates a regional service definition.

    let
        acm = defineRegional "acm" "2015-12-08" json signV4
            (setJsonVersion "1.1" >> setTargetPrefix "CertificateManager")
        service = acm "ca-central-1"
    in
    ( service |> endpointPrefix
    , service |> host
    , service |> targetPrefix
    )
    --> ( "acm"
    --> , "acm.ca-central-1.amazonaws.com"
    --> , "CertificateManager"
    --> )

Your client library should not provide the region. Instead it should expose
a function `Region -> Service` by leaving out the last argument.

-}
defineRegional :
    String
    -> ApiVersion
    -> Protocol
    -> Signer
    -> (Service -> Service)
    -> Region
    -> Service
defineRegional prefix apiVersion proto signerType extra rgn =
    case
        define prefix apiVersion proto signerType extra
    of
        Service s ->
            Service { s | endpoint = RegionalEndpoint rgn }



-- OPTIONAL SETTERS


{-| Set the JSON apiVersion.

Use this if `jsonVersion` is provided in the metadata.

-}
setJsonVersion : String -> Service -> Service
setJsonVersion jsonVersion (Service service) =
    Service { service | jsonVersion = Just jsonVersion }


{-| Use Digital Ocean Spaces as the backend service provider.

Changes the way hostnames are resolved.

-}
toDigitalOceanSpaces : Service -> Service
toDigitalOceanSpaces (Service service) =
    Service
        { service
            | hostResolver =
                \endpoint _ ->
                    case endpoint of
                        GlobalEndpoint ->
                            "nyc3.digitaloceanspaces.com"

                        RegionalEndpoint rgn ->
                            rgn ++ ".digitaloceanspaces.com"
            , regionResolver =
                \endpoint ->
                    case endpoint of
                        GlobalEndpoint ->
                            "nyc3"

                        RegionalEndpoint rgn ->
                            rgn
        }


{-| Set the signing name for the service.

Use this if `signingName` is provided in the metadata.

-}
setSigningName : String -> Service -> Service
setSigningName name (Service service) =
    Service { service | signingName = Just name }


{-| Set the target prefix for the service.

Use this if `targetPrefix` is provided in the metadata.

-}
setTargetPrefix : String -> Service -> Service
setTargetPrefix prefix (Service service) =
    Service { service | targetPrefix = prefix }


{-| Set the timestamp format for the service.

Use this if `timestampFormat` is provided in the metadata.

-}
setTimestampFormat : TimestampFormat -> Service -> Service
setTimestampFormat format (Service service) =
    Service { service | timestampFormat = format }


{-| Set the XML namespace for the service.

Use this if `xmlNamespace` is provided in the metadata.

-}
setXmlNamespace : String -> Service -> Service
setXmlNamespace namespace (Service service) =
    Service { service | xmlNamespace = Just namespace }



-- GETTERS


{-| Set the target prefix.
-}
targetPrefix : Service -> String
targetPrefix (Service spec) =
    spec.targetPrefix


{-| Name of the service.
-}
endpointPrefix : Service -> String
endpointPrefix (Service spec) =
    spec.endpointPrefix


{-| Service signature version.
-}
signer : Service -> Signer
signer (Service spec) =
    spec.signer


{-| Protocol of the service.
-}
protocol : Service -> Protocol
protocol (Service spec) =
    spec.protocol


{-| Gets the service JSON content type header value.
-}
jsonContentType : Service -> String
jsonContentType (Service spec) =
    (case spec.protocol of
        REST_XML ->
            "application/xml"

        _ ->
            case spec.jsonVersion of
                Just apiVersion ->
                    "application/x-amz-json-" ++ apiVersion

                Nothing ->
                    "application/json"
    )
        ++ "; charset=utf-8"


{-| Gets the service Accept header value.
-}
acceptType : Service -> String
acceptType (Service spec) =
    case spec.protocol of
        REST_XML ->
            "application/xml"

        _ ->
            "application/json"



-- ENDPOINTS


{-| Defines an AWS service endpoint.
-}
type Endpoint
    = GlobalEndpoint
    | RegionalEndpoint Region


{-| An AWS region string.

For example `"us-east-1"`.

-}
type alias Region =
    String


{-| Create a regional endpoint given a region.
-}
regionalEndpoint : Region -> Endpoint
regionalEndpoint =
    RegionalEndpoint


{-| Create a global endpoint.
-}
globalEndpoint : Endpoint
globalEndpoint =
    GlobalEndpoint


{-| Service endpoint as a hostname.
-}
host : Service -> String
host (Service spec) =
    spec.hostResolver spec.endpoint spec.endpointPrefix


defaultHostResolver : Endpoint -> String -> String
defaultHostResolver endpoint prefix =
    case endpoint of
        GlobalEndpoint ->
            prefix ++ ".amazonaws.com"

        RegionalEndpoint rgn ->
            prefix ++ "." ++ rgn ++ ".amazonaws.com"


{-| Service region.
-}
region : Service -> String
region (Service { endpoint, regionResolver }) =
    regionResolver endpoint


defaultRegionResolver : Endpoint -> String
defaultRegionResolver endpoint =
    case endpoint of
        RegionalEndpoint rgn ->
            rgn

        GlobalEndpoint ->
            -- See http://docs.aws.amazon.com/general/latest/gr/sigv4_changes.html
            "us-east-1"



-- PROTOCOLS


{-| Defines the different protocols that AWS services can use.
-}
type Protocol
    = EC2
    | JSON
    | QUERY
    | REST_JSON
    | REST_XML


{-| Enumerates the protocols.
-}
protocolEnum : Enum Protocol
protocolEnum =
    Enum.define
        [ EC2
        , JSON
        , QUERY
        , REST_JSON
        , REST_XML
        ]
        (\val ->
            case val of
                EC2 ->
                    "ec2"

                JSON ->
                    "json"

                QUERY ->
                    "query"

                REST_JSON ->
                    "rest-json"

                REST_XML ->
                    "rest-xml"
        )



-- SIGNERS


{-| Defines the different signing schemes that AWS services can use.
-}
type Signer
    = SignV4
    | SignS3


{-| Enumerates the signing schemes.
-}
signerEnum : Enum Signer
signerEnum =
    Enum.define
        [ SignV4
        , SignS3
        ]
        (\val ->
            case val of
                SignV4 ->
                    "v4"

                SignS3 ->
                    "s3"
        )



-- TIMESTAMP FORMATS


{-| Defines the different timestamp formats that AWS services can use.
-}
type TimestampFormat
    = ISO8601
    | RFC822
    | UnixTimestamp


{-| Enumerates the timestamp formats.
-}
timestampFormatEnum : Enum TimestampFormat
timestampFormatEnum =
    Enum.define
        [ ISO8601
        , RFC822
        , UnixTimestamp
        ]
        (\val ->
            case val of
                ISO8601 ->
                    "iso8601"

                RFC822 ->
                    "rfc822"

                UnixTimestamp ->
                    "unixTimestamp"
        )


{-| Use the timestamp format ISO8601.
-}
iso8601 : TimestampFormat
iso8601 =
    ISO8601


{-| Use the timestamp format RCF822.
-}
rfc822 : TimestampFormat
rfc822 =
    RFC822


{-| Use the timestamp format UnixTimestamp.
-}
unixTimestamp : TimestampFormat
unixTimestamp =
    UnixTimestamp



-- HELPERS


defaultTargetPrefix : String -> ApiVersion -> String
defaultTargetPrefix prefix apiVersion =
    "AWS"
        ++ String.toUpper prefix
        ++ "_"
        ++ (apiVersion |> String.split "-" |> String.join "")


{-| See aws-sdk-js

`lib/model/shape.js`: function TimestampShape

-}
defaultTimestampFormat : Protocol -> TimestampFormat
defaultTimestampFormat proto =
    case proto of
        JSON ->
            UnixTimestamp

        REST_JSON ->
            UnixTimestamp

        _ ->
            ISO8601
