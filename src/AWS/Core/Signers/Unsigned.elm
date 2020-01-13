module AWS.Core.Signers.Unsigned exposing (filterHeaders, formatPosix, headers, sign)

import AWS.Core.Body exposing (Body, explicitMimetype)
import AWS.Core.Request exposing (Unsigned)
import AWS.Core.Service as Service exposing (Service)
import AWS.Core.Signers.Canonical exposing (canonical, canonicalPayload, signedHeaders)
import Http
import Iso8601
import Json.Decode as Decode
import Regex
import Task exposing (Task)
import Time exposing (Posix)


sign :
    Service
    -> Posix
    -> Unsigned a
    -> Task Http.Error a
sign service date req =
    let
        responseDecoder response =
            case response of
                Http.BadUrl_ url ->
                    Http.BadUrl url |> Err

                Http.Timeout_ ->
                    Http.Timeout |> Err

                Http.NetworkError_ ->
                    Http.NetworkError |> Err

                Http.BadStatus_ metadata _ ->
                    Http.BadStatus metadata.statusCode |> Err

                Http.GoodStatus_ metadata body ->
                    Decode.decodeString req.decoder body
                        |> Result.mapError (\decodeError -> Decode.errorToString decodeError |> Http.BadBody)

        resolver =
            case req.responseParser of
                Just parser ->
                    Http.stringResolver parser

                Nothing ->
                    Http.stringResolver responseDecoder
    in
    Http.task
        { method = req.method
        , headers =
            headers service date req.body req.headers
                |> List.map (\( key, val ) -> Http.header key val)
        , url = AWS.Core.Request.url service req
        , body = AWS.Core.Body.toHttp req.body
        , resolver = resolver
        , timeout = Nothing
        }


headers : Service -> Posix -> Body -> List ( String, String ) -> List ( String, String )
headers service date body extraHeaders =
    let
        extraNames =
            List.map Tuple.first extraHeaders
                |> List.map String.toLower
    in
    List.concat
        [ extraHeaders
        , [ ( "x-amz-date", formatPosix date )
          , ( "x-amz-content-sha256", canonicalPayload body )
          ]
        , if List.member "accept" extraNames then
            []

          else
            [ ( "Accept", Service.acceptType service ) ]
        , if List.member "content-type" extraNames || explicitMimetype body /= Nothing then
            []

          else
            [ ( "Content-Type", Service.jsonContentType service ) ]
        ]


formatPosix : Posix -> String
formatPosix date =
    date
        |> Iso8601.fromTime
        |> Regex.replace
            (Regex.fromString "([-:]|\\.\\d{3})" |> Maybe.withDefault Regex.never)
            (\_ -> "")



-- Expects headersToRemove to be all lower-case


filterHeaders : List String -> List ( String, String ) -> List ( String, String )
filterHeaders headersToRemove headersList =
    let
        matches =
            \( head, _ ) ->
                not <| List.member (String.toLower head) headersToRemove
    in
    List.filter matches headersList
