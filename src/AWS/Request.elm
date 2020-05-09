module AWS.Request exposing
    ( HttpStatus(..)
    , ResponseDecoder
    , Unsigned
    , queryString
    , unsigned
    , url
    )

{-| Internal representation of a request.
-}

import AWS.Body as Body exposing (Body)
import AWS.QueryString as QueryString
import AWS.Service as Service exposing (Service)
import AWS.Uri
import Http exposing (Error, Metadata, Response)
import Json.Decode exposing (Decoder)



-- Types from Http module for reference.
--
-- type Response body
--     = BadUrl_ String --> Map to BadUrl
--     | Timeout_ --> Map to Timeout
--     | NetworkError_ --> Map to NetworkError
--     | BadStatus_ Metadata body
--     | GoodStatus_ Metadata body
--
-- type alias Metadata =
--     { url : String
--     , statusCode : Int
--     , statusText : String
--     , headers : Dict String String
--     }
--
-- type Error
--     = BadUrl String
--     | Timeout
--     | NetworkError
--     | BadStatus Int
--     | BadBody String


type alias ResponseDecoder a =
    HttpStatus -> Metadata -> String -> Result Http.Error a


type HttpStatus
    = GoodStatus
    | BadStatus


type alias Unsigned a =
    { name : String
    , method : String
    , path : String
    , body : Body
    , headers : List ( String, String )
    , query : List ( String, String )
    , decoder : ResponseDecoder a
    }


unsigned :
    String
    -> String
    -> String
    -> Body
    -> ResponseDecoder a
    -> Unsigned a
unsigned name method uri body decoder =
    { name = name
    , method = method
    , path = uri
    , body = body
    , headers = []
    , query = []
    , decoder = decoder
    }


url : Service -> Unsigned a -> String
url service { path, query } =
    "https://"
        ++ Service.host service
        ++ path
        ++ queryString query


queryString : List ( String, String ) -> String
queryString params =
    case params of
        [] ->
            ""

        _ ->
            params
                |> List.foldl
                    (\( key, val ) qs ->
                        qs |> QueryString.add (AWS.Uri.percentEncode key) val
                    )
                    QueryString.empty
                |> QueryString.render
