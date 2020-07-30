module AWS.Internal.V4 exposing (sign)

{-| V4 request signing implementation.

<http://docs.aws.amazon.com/waf/latest/developerguide/authenticating-requests.html>

-}

import AWS.Credentials as Credentials exposing (Credentials)
import AWS.Internal.Body exposing (Body, explicitMimetype)
import AWS.Internal.Canonical exposing (canonical, canonicalPayload, signedHeaders)
import AWS.Internal.Request exposing (Request, ResponseDecoder, ResponseStatus(..))
import AWS.Internal.Service as Service exposing (Service)
import AWS.Internal.UrlBuilder
import Crypto.HMAC exposing (sha256)
import Http
import Iso8601
import Json.Decode as Decode
import Regex
import Task exposing (Task)
import Time exposing (Posix)
import Word.Bytes as Bytes
import Word.Hex as Hex


{-| Prepares a request and signs it with the V4 signing scheme.
-}
sign :
    Service
    -> Credentials
    -> Posix
    -> Request err a
    -> Task Http.Error (Result err a)
sign service creds date req =
    let
        responseDecoder response =
            case response of
                Http.BadUrl_ url ->
                    Http.BadUrl url |> Err

                Http.Timeout_ ->
                    Http.Timeout |> Err

                Http.NetworkError_ ->
                    Http.NetworkError |> Err

                Http.BadStatus_ metadata body ->
                    req.decoder BadStatus_ metadata body

                Http.GoodStatus_ metadata body ->
                    req.decoder GoodStatus_ metadata body

        resolver =
            Http.stringResolver responseDecoder
    in
    Http.task
        { method = req.method
        , headers =
            headers service date req.body req.headers
                |> addAuthorization service creds date req
                |> addSessionToken creds
                |> List.map (\( key, val ) -> Http.header key val)
        , url = AWS.Internal.UrlBuilder.url service req
        , body = AWS.Internal.Body.toHttp req.body
        , resolver = resolver
        , timeout = Nothing
        }


algorithm : String
algorithm =
    "AWS4-HMAC-SHA256"


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
            [ ( "Content-Type", Service.contentType service ) ]
        ]


formatPosix : Posix -> String
formatPosix date =
    date
        |> Iso8601.fromTime
        |> Regex.replace
            (Regex.fromString "([-:]|\\.\\d{3})" |> Maybe.withDefault Regex.never)
            (\_ -> "")


addSessionToken :
    Credentials
    -> List ( String, String )
    -> List ( String, String )
addSessionToken creds headersList =
    creds.sessionToken
        |> Maybe.map
            (\token ->
                ( "x-amz-security-token", token ) :: headersList
            )
        |> Maybe.withDefault headersList


addAuthorization :
    Service
    -> Credentials
    -> Posix
    -> Request err a
    -> List ( String, String )
    -> List ( String, String )
addAuthorization service creds date req headersList =
    [ ( "Authorization"
      , authorization creds
            date
            service
            req
            (headersList |> (::) ( "Host", Service.host service ))
      )
    ]
        |> List.append headersList



-- Expects headersToRemove to be all lower-case


filterHeaders : List String -> List ( String, String ) -> List ( String, String )
filterHeaders headersToRemove headersList =
    let
        matches =
            \( head, _ ) ->
                not <| List.member (String.toLower head) headersToRemove
    in
    List.filter matches headersList


authorization :
    Credentials
    -> Posix
    -> Service
    -> Request err a
    -> List ( String, String )
    -> String
authorization creds date service req rawHeaders =
    let
        -- Content-Type & Accept tend to be amended by Http.request
        filteredHeaders =
            filterHeaders [ "content-type", "accept" ] rawHeaders

        canon =
            canonical service.signer req.method req.path filteredHeaders req.query req.body

        scope =
            credentialScope date creds service
    in
    [ "AWS4-HMAC-SHA256 Credential="
        ++ creds.accessKeyId
        ++ "/"
        ++ scope
    , "SignedHeaders="
        ++ signedHeaders filteredHeaders
    , "Signature="
        ++ signature creds service date (stringToSign algorithm date scope canon)
    ]
        |> String.join ", "


credentialScope : Posix -> Credentials -> Service -> String
credentialScope date creds service =
    [ date |> formatPosix |> String.slice 0 8
    , Service.region service
    , service.endpointPrefix
    , "aws4_request"
    ]
        |> String.join "/"


signature : Credentials -> Service -> Posix -> String -> String
signature creds service date toSign =
    let
        digest =
            \message key ->
                Crypto.HMAC.digestBytes sha256
                    key
                    (Bytes.fromUTF8 message)
    in
    creds.secretAccessKey
        |> (++) "AWS4"
        |> Bytes.fromUTF8
        |> digest (formatPosix date |> String.slice 0 8)
        |> digest (Service.region service)
        |> digest service.endpointPrefix
        |> digest "aws4_request"
        |> digest toSign
        |> Hex.fromByteList


stringToSign : String -> Posix -> String -> String -> String
stringToSign alg date scope canon =
    [ alg
    , date |> formatPosix
    , scope
    , canon
    ]
        |> String.join "\n"
