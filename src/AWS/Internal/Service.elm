module AWS.Internal.Service exposing (acceptType, contentType, host, region)

import AWS.Service exposing (Protocol(..), Service)


{-| Service endpoint as a hostname.
-}
host : Service -> String
host spec =
    spec.hostResolver spec.endpoint spec.endpointPrefix


{-| Service region.
-}
region : Service -> String
region { endpoint, regionResolver } =
    regionResolver endpoint


{-| Gets the service content type header value.
-}
contentType : Service -> String
contentType spec =
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
acceptType spec =
    case spec.protocol of
        REST_XML ->
            "application/xml"

        _ ->
            "application/json"
