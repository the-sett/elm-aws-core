module AWS.Http exposing
    ( send, sendUnsigned
    , Method(..), Path, Request
    , request, requestWithJsonDecoder
    , setResponseParser
    , Body, MimeType
    , emptyBody, stringBody, jsonBody
    , addHeaders, addQuery
    )

{-| Handling of HTTP requests to AWS Services.


# Tasks for sending requests to AWS.

@docs send, sendUnsigned


# Build a Request

@docs Method, Path, Request
@docs request, requestWithJsonDecoder
@docs setResponseParser


# Build th HTTP Body of a Request

@docs Body, MimeType
@docs emptyBody, stringBody, jsonBody


# Add headers or query parameters to a Request

@docs addHeaders, addQuery

-}

import AWS.Body
import AWS.Credentials exposing (Credentials)
import AWS.Request exposing (Unsigned)
import AWS.Service as Service exposing (Protocol(..), Service, Signer(..))
import AWS.Signers.Unsigned as Unsigned
import AWS.Signers.V4 as V4
import Http
import Json.Decode as Decode
import Json.Encode
import Task exposing (Task)
import Time exposing (Posix)



--=== Tasks for sending requests to AWS.


{-| Signs and sends an AWS Request to a service.
-}
send :
    Service
    -> Credentials
    -> Request a
    -> Task.Task Http.Error a
send service credentials req =
    let
        prepareRequest : Request a -> Request a
        prepareRequest innerReq =
            case Service.protocol service of
                JSON ->
                    addHeaders
                        [ ( "x-amz-target", Service.targetPrefix service ++ "." ++ innerReq.name ) ]
                        innerReq

                _ ->
                    innerReq

        signWithTimestamp : Request a -> Posix -> Task Http.Error a
        signWithTimestamp innerReq posix =
            case Service.signer service of
                SignV4 ->
                    V4.sign service credentials posix innerReq

                SignS3 ->
                    Task.fail (Http.BadBody "TODO: S3 Signing Scheme not implemented.")
    in
    Time.now |> Task.andThen (prepareRequest req |> signWithTimestamp)


{-| Sends an AWS Request to a service wihtout signing it.
-}
sendUnsigned :
    Service
    -> Request a
    -> Task.Task Http.Error a
sendUnsigned service req =
    let
        prepareRequest : Request a -> Request a
        prepareRequest innerReq =
            case Service.protocol service of
                JSON ->
                    addHeaders
                        [ ( "x-amz-target", Service.targetPrefix service ++ "." ++ innerReq.name ) ]
                        innerReq

                _ ->
                    innerReq

        withTimestamp : Request a -> Posix -> Task Http.Error a
        withTimestamp innerReq posix =
            Unsigned.prepare service posix innerReq
    in
    Time.now |> Task.andThen (prepareRequest req |> withTimestamp)



--=== Build a request


{-| Holds an unsigned AWS HTTP request.
-}
type alias Request a =
    AWS.Request.Unsigned a


{-| HTTP request methods.
-}
type Method
    = DELETE
    | GET
    | HEAD
    | OPTIONS
    | POST
    | PUT


{-| Request path.
-}
type alias Path =
    String


{-| Create an AWS HTTP unsigned request.

    request "Function" GET emptyBody parser

-}
request :
    String
    -> Method
    -> Path
    -> Body
    -> (String -> Result String a)
    -> Request a
request name method path body decoder =
    AWS.Request.unsigned name (methodToString method) path body decoder


{-| Create an AWS HTTP unsigned request that expects a JSON response.

    request "Function" GET emptyBody decodeFn

-}
requestWithJsonDecoder :
    String
    -> Method
    -> Path
    -> Body
    -> Decode.Decoder a
    -> Request a
requestWithJsonDecoder name method path body decoder =
    request name
        method
        path
        body
        (Decode.decodeString decoder
            >> Result.mapError Decode.errorToString
        )


{-| Set a parser for the entire Http.Response. Overrides the request decoder.
-}
setResponseParser : (Http.Response String -> Result Http.Error a) -> Request a -> Request a
setResponseParser parser req =
    { req | responseParser = Just parser }



--=== Build th HTTP Body of a Request


{-| Holds a request body.
-}
type alias Body =
    AWS.Body.Body


{-| MIME type.

See <https://en.wikipedia.org/wiki/Media_type>

-}
type alias MimeType =
    String


{-| Create an empty body.
-}
emptyBody : Body
emptyBody =
    AWS.Body.empty


{-| Create a body containing a JSON value.

This will automatically add the `Content-Type: application/json` header.

-}
jsonBody : Json.Encode.Value -> Body
jsonBody =
    AWS.Body.json


{-| Create a body with a custom MIME type and the given string as content.

    stringBody "text/html" "<html><body><h1>Hello</h1></body></html>"

-}
stringBody : MimeType -> String -> Body
stringBody =
    AWS.Body.string



--=== Add headers or query parameters to a Request


{-| Appends headers to an AWS HTTP unsigned request.

See the `AWS.KVEncode` for encoder functions to build the headers with.

-}
addHeaders : List ( String, String ) -> Request a -> Request a
addHeaders headers req =
    { req | headers = List.append req.headers headers }


{-| Appends query arguments to an AWS HTTP unsigned request.

See the `AWS.KVEncode` for encoder functions to build the query parameters with.

-}
addQuery : List ( String, String ) -> Request a -> Request a
addQuery query req =
    { req | query = List.append req.query query }


methodToString : Method -> String
methodToString meth =
    case meth of
        DELETE ->
            "DELETE"

        GET ->
            "GET"

        HEAD ->
            "HEAD"

        OPTIONS ->
            "OPTIONS"

        POST ->
            "POST"

        PUT ->
            "PUT"
