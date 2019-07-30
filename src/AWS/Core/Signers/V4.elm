module AWS.Core.Signers.V4 exposing (addAuthorization, addSessionToken, algorithm, authorization, credentialScope, filterHeaders, formatPosix, headers, sign, signature, stringToSign)

import AWS.Core.Body exposing (Body, explicitMimetype)
import AWS.Core.Credentials as Credentials exposing (Credentials)
import AWS.Core.Request exposing (Unsigned)
import AWS.Core.Service as Service exposing (Service)
import AWS.Core.Signers.Canonical exposing (canonical, canonicalPayload, signedHeaders)
import Crypto.HMAC exposing (sha256)
import Http
import Iso8601
import Regex
import Time exposing (Posix)
import Word.Bytes as Bytes
import Word.Hex as Hex



-- http://docs.aws.amazon.com/waf/latest/developerguide/authenticating-requests.html


sign :
    Service
    -> Credentials
    -> Posix
    -> Unsigned a
    -> (Result Http.Error a -> msg)
    -> Cmd msg
sign service creds date req tagger =
    Http.request
        { method = req.method
        , headers =
            headers service date req.body req.headers
                |> addAuthorization service creds date req
                |> addSessionToken creds
                |> List.map (\( key, val ) -> Http.header key val)
        , url = AWS.Core.Request.url service req
        , body = AWS.Core.Body.toHttp req.body
        , expect =
            case req.responseParser of
                Just parser ->
                    Http.expectStringResponse tagger parser

                Nothing ->
                    Http.expectJson tagger req.decoder
        , timeout = Nothing
        , tracker = Nothing
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
            [ ( "Content-Type", Service.jsonContentType service ) ]
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
    creds
        |> Credentials.sessionToken
        |> Maybe.map
            (\token ->
                ( "x-amz-security-token", token ) :: headersList
            )
        |> Maybe.withDefault headersList


addAuthorization :
    Service
    -> Credentials
    -> Posix
    -> Unsigned a
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
    -> Unsigned a
    -> List ( String, String )
    -> String
authorization creds date service req rawHeaders =
    let
        -- Content-Type & Accept tend to be amended by Http.request
        filteredHeaders =
            filterHeaders [ "content-type", "accept" ] rawHeaders

        canon =
            canonical (Service.signer service) req.method req.path filteredHeaders req.query req.body

        scope =
            credentialScope date creds service
    in
    [ "AWS4-HMAC-SHA256 Credential="
        ++ Credentials.accessKeyId creds
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
    , Service.endpointPrefix service
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
    creds
        |> Credentials.secretAccessKey
        |> (++) "AWS4"
        |> Bytes.fromUTF8
        |> digest (formatPosix date |> String.slice 0 8)
        |> digest (Service.region service)
        |> digest (Service.endpointPrefix service)
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
