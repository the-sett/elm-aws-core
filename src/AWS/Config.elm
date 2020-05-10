module AWS.Config exposing
    ( ServiceConfig
    , defineGlobal, defineRegional
    , ApiVersion, Protocol(..), Signer(..), TimestampFormat(..), Region, Endpoint(..)
    , withJsonVersion, withSigningName, withTargetPrefix, withTimestampFormat, withXmlNamespace
    )

{-| AWS service configuration.


# Define a Service.

@docs ServiceConfig
@docs defineGlobal, defineRegional
@docs ApiVersion, Protocol, Signer, TimestampFormat, Region, Endpoint


# Optional properties that can be added to a Service.

@docs withJsonVersion, withSigningName, withTargetPrefix, withTimestampFormat, withXmlNamespace


# Digital Ocean Services

Can be used to map the host name to Digial Ocean instead of AWS. Many AWS services
are proxied by Digital Ocean.

-}

import Enum exposing (Enum)


{-| Configures an AWS service.
-}
type alias ServiceConfig =
    { endpointPrefix : String
    , apiVersion : ApiVersion
    , protocol : Protocol
    , signer : Signer
    , targetPrefix : String
    , timestampFormat : TimestampFormat
    , endpoint : Endpoint
    , jsonVersion : Maybe String
    , signingName : Maybe String
    , xmlNamespace : Maybe String
    }


{-| Creates a global service definition.
-}
defineGlobal : String -> ApiVersion -> Protocol -> Signer -> ServiceConfig
defineGlobal prefix apiVersion proto signerType =
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
    }


{-| Creates a regional service definition.
-}
defineRegional : String -> ApiVersion -> Protocol -> Signer -> Region -> ServiceConfig
defineRegional prefix apiVersion proto signerType rgn =
    let
        svc =
            defineGlobal prefix apiVersion proto signerType
    in
    { svc | endpoint = RegionalEndpoint rgn }


{-| Version of a service.
-}
type alias ApiVersion =
    String


{-| Defines the different protocols that AWS services can use.
-}
type Protocol
    = EC2
    | JSON
    | QUERY
    | REST_JSON
    | REST_XML


{-| Defines the different signing schemes that AWS services can use.
-}
type Signer
    = SignV4
    | SignS3


{-| Defines the different timestamp formats that AWS services can use.
-}
type TimestampFormat
    = ISO8601
    | RFC822
    | UnixTimestamp


{-| An AWS region string.

For example `"us-east-1"`.

-}
type alias Region =
    String


{-| Defines an AWS service endpoint.
-}
type Endpoint
    = GlobalEndpoint
    | RegionalEndpoint Region



--=== Optional properties that can be added to a Service.


{-| Set the JSON apiVersion.

Use this if `jsonVersion` is provided in the metadata.

-}
withJsonVersion : String -> ServiceConfig -> ServiceConfig
withJsonVersion jsonVersion service =
    { service | jsonVersion = Just jsonVersion }


{-| Set the signing name for the service.

Use this if `signingName` is provided in the metadata.

-}
withSigningName : String -> ServiceConfig -> ServiceConfig
withSigningName name service =
    { service | signingName = Just name }


{-| Set the target prefix for the service.

Use this if `targetPrefix` is provided in the metadata.

-}
withTargetPrefix : String -> ServiceConfig -> ServiceConfig
withTargetPrefix prefix service =
    { service | targetPrefix = prefix }


{-| Set the timestamp format for the service.

Use this if `timestampFormat` is provided in the metadata.

-}
withTimestampFormat : TimestampFormat -> ServiceConfig -> ServiceConfig
withTimestampFormat format service =
    { service | timestampFormat = format }


{-| Set the XML namespace for the service.

Use this if `xmlNamespace` is provided in the metadata.

-}
withXmlNamespace : String -> ServiceConfig -> ServiceConfig
withXmlNamespace namespace service =
    { service | xmlNamespace = Just namespace }



--=== Digital Ocean Services.
{- Use Digital Ocean Spaces as the backend service provider.

   Changes the way hostnames are resolved.

-}
-- toDigitalOceanService : ServiceConfig -> Service
-- toDigitalOceanService config =
--     { endpointPrefix = config.endpointPrefix
--     , apiVersion = config.apiVersion
--     , protocol = config.protocol
--     , signer = config.signer
--     , targetPrefix = config.targetPrefix
--     , timestampFormat = config.timestampFormat
--     , endpoint = config.endpoint
--     , jsonVersion = config.jsonVersion
--     , signingName = config.signingName
--     , xmlNamespace = config.xmlNamespace
--     , hostResolver =
--         \endpoint _ ->
--             case endpoint of
--                 GlobalEndpoint ->
--                     "nyc3.digitaloceanspaces.com"
--
--                 RegionalEndpoint rgn ->
--                     rgn ++ ".digitaloceanspaces.com"
--     , regionResolver =
--         \endpoint ->
--             case endpoint of
--                 GlobalEndpoint ->
--                     "nyc3"
--
--                 RegionalEndpoint rgn ->
--                     rgn
--     }
--=== Helpers


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



-- These not needed here. Put them in elm-aws-codegen.


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
