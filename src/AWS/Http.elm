module AWS.Http exposing
    ( send, sendUnsigned
    , Method(..), Path, Request
    , request
    , Body, MimeType
    , emptyBody, stringBody, jsonBody
    , addHeaders, addQuery
    , fullDecoder, jsonFullDecoder, stringBodyDecoder, jsonBodyDecoder, constantDecoder
    )

{-| Handling of HTTP requests to AWS Services.


# Tasks for sending requests to AWS.

@docs send, sendUnsigned


# Build a Request

@docs Method, Path, Request
@docs request


# Build the HTTP Body of a Request

@docs Body, MimeType
@docs emptyBody, stringBody, jsonBody


# Add headers or query parameters to a Request

@docs addHeaders, addQuery


# Build decoders to interpret the response.

@docs fullDecoder, jsonFullDecoder, stringBodyDecoder, jsonBodyDecoder, constantDecoder

-}

import AWS.Config exposing (Protocol(..), Signer(..))
import AWS.Credentials exposing (Credentials)
import AWS.Internal.Body
import AWS.Internal.Request exposing (HttpStatus(..), ResponseDecoder, Unsigned)
import AWS.Internal.Service as IntService exposing (Service)
import AWS.Internal.Unsigned as Unsigned
import AWS.Internal.V4 as V4
import Http exposing (Metadata)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode
import Task exposing (Task)
import Time exposing (Posix)



--=== Tasks for sending requests to AWS.


{-| Signs and sends a `Request` to a `Service`.
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
            case service.protocol of
                JSON ->
                    addHeaders
                        [ ( "x-amz-target", service.targetPrefix ++ "." ++ innerReq.name ) ]
                        innerReq

                _ ->
                    innerReq

        signWithTimestamp : Request a -> Posix -> Task Http.Error a
        signWithTimestamp innerReq posix =
            case service.signer of
                SignV4 ->
                    V4.sign service credentials posix innerReq

                SignS3 ->
                    Task.fail (Http.BadBody "TODO: S3 Signing Scheme not implemented.")
    in
    Time.now |> Task.andThen (prepareRequest req |> signWithTimestamp)


{-| Sends a `Request` without signing it.
-}
sendUnsigned :
    Service
    -> Request a
    -> Task.Task Http.Error a
sendUnsigned service req =
    let
        prepareRequest : Request a -> Request a
        prepareRequest innerReq =
            case service.protocol of
                JSON ->
                    addHeaders
                        [ ( "x-amz-target", service.targetPrefix ++ "." ++ innerReq.name ) ]
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
    AWS.Internal.Request.Unsigned a


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


{-| Creates an unsigned HTTP request to an AWS service.
-}
request :
    String
    -> Method
    -> Path
    -> Body
    -> ResponseDecoder a
    -> Request a
request name method path body decoder =
    AWS.Internal.Request.unsigned name (methodToString method) path body decoder



--=== Build th HTTP Body of a Request


{-| Holds a request body.
-}
type alias Body =
    AWS.Internal.Body.Body


{-| MIME type.

See <https://en.wikipedia.org/wiki/Media_type>

-}
type alias MimeType =
    String


{-| Create an empty body.
-}
emptyBody : Body
emptyBody =
    AWS.Internal.Body.empty


{-| Create a body containing a JSON value.

This will automatically add the `Content-Type: application/json` header.

-}
jsonBody : Json.Encode.Value -> Body
jsonBody =
    AWS.Internal.Body.json


{-| Create a body with a custom MIME type and the given string as content.

    stringBody "text/html" "<html><body><h1>Hello</h1></body></html>"

-}
stringBody : MimeType -> String -> Body
stringBody =
    AWS.Internal.Body.string



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



--=== Build decoders to interpret the response.


{-| A full decoder for the response that can look at the status code, metadata
including headers and so on. The body is presented as a `String` for parsing.

It is possible to report an error as a String when interpreting the response, and
this will be mapped onto `Http.BadBody` when present.

-}
fullDecoder : (HttpStatus -> Metadata -> String -> Result String a) -> ResponseDecoder a
fullDecoder decodeFn =
    \status metadata body ->
        case decodeFn status metadata body of
            Ok val ->
                Ok val

            Err err ->
                Http.BadBody err |> Err


{-| A full JSON decoder for the response that can look at the status code, metadata
including headers and so on. The body is presented as a JSON `Value` for decoding.

Any decoder error is mapped onto `Http.BadBody` as a `String` when present using
`Decode.errorToString`.

-}
jsonFullDecoder : (HttpStatus -> Metadata -> Decoder a) -> ResponseDecoder a
jsonFullDecoder decodeFn =
    \status metadata body ->
        case Decode.decodeString (decodeFn status metadata) body of
            Ok val ->
                Ok val

            Err err ->
                Http.BadBody (Decode.errorToString err) |> Err


{-| A decoder for the response that uses only the body presented as a `String`
for parsing.

It is possible to report an error as a String when interpreting the response, and
this will be mapped onto `Http.BadBody` when present.

Note that this decoder is only used when the response is Http.GoodStatus\_. An
Http.BadStatus\_ is always mapped to Http.BadStatus without attempting to decode
the body. If you need to handle things that Elm HTTP regards as BadStatus\_, use
one of the 'full' decoders.

-}
stringBodyDecoder : (String -> Result String a) -> ResponseDecoder a
stringBodyDecoder decodeFn =
    \status metadata body ->
        case status of
            GoodStatus ->
                case decodeFn body of
                    Ok val ->
                        Ok val

                    Err err ->
                        Http.BadBody err |> Err

            BadStatus ->
                Http.BadStatus metadata.statusCode |> Err


{-| A decoder for the response that uses only the body presented as a JSON `Value`
for decoding.

Any decoder error is mapped onto `Http.BadBody` as a `String` when present using
`Decode.errorToString`.

Note that this decoder is only used when the response is Http.GoodStatus\_. An
Http.BadStatus\_ is always mapped to Http.BadStatus without attempting to decode
the body. If you need to handle things that Elm HTTP regards as BadStatus\_, use
one of the 'full' decoders.

-}
jsonBodyDecoder : Decoder a -> ResponseDecoder a
jsonBodyDecoder decodeFn =
    \status metadata body ->
        case status of
            GoodStatus ->
                case Decode.decodeString decodeFn body of
                    Ok val ->
                        Ok val

                    Err err ->
                        Http.BadBody (Decode.errorToString err) |> Err

            BadStatus ->
                Http.BadStatus metadata.statusCode |> Err


{-| Not all AWS service produce a response that contains useful information.

The `constantDecoder` is helpful in those situations and just produces whatever
value you give it once AWS has responded.

Note that this decoder is only used when the response is Http.GoodStatus\_. An
Http.BadStatus\_ is always mapped to Http.BadStatus without attempting to decode
the body. If you need to handle things that Elm HTTP regards as BadStatus\_, use
one of the 'full' decoders.

-}
constantDecoder : a -> ResponseDecoder a
constantDecoder val =
    \status metadata _ ->
        case status of
            GoodStatus ->
                Ok val

            BadStatus ->
                Http.BadStatus metadata.statusCode |> Err


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
