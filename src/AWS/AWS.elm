module AWS.AWS exposing (toAWSService)

{-| Flarge barge barge.

@docs toAWSService

-}

import AWS.Internal.Service exposing (Service)
import AWS.Service exposing (Endpoint(..), ServiceConfig)


{-| Build an AWS service.
-}
toAWSService : ServiceConfig -> Service
toAWSService config =
    { endpointPrefix = config.endpointPrefix
    , apiVersion = config.apiVersion
    , protocol = config.protocol
    , signer = config.signer
    , targetPrefix = config.targetPrefix
    , timestampFormat = config.timestampFormat
    , endpoint = config.endpoint
    , jsonVersion = config.jsonVersion
    , signingName = config.signingName
    , xmlNamespace = config.xmlNamespace
    , hostResolver = defaultHostResolver
    , regionResolver = defaultRegionResolver
    }


defaultHostResolver : Endpoint -> String -> String
defaultHostResolver endpoint prefix =
    case endpoint of
        GlobalEndpoint ->
            prefix ++ ".amazonaws.com"

        RegionalEndpoint rgn ->
            prefix ++ "." ++ rgn ++ ".amazonaws.com"


defaultRegionResolver : Endpoint -> String
defaultRegionResolver endpoint =
    case endpoint of
        RegionalEndpoint rgn ->
            rgn

        GlobalEndpoint ->
            -- See http://docs.aws.amazon.com/general/latest/gr/sigv4_changes.html
            "us-east-1"
