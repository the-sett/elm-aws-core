module AWS.Internal.Request exposing
    ( Request
    , ResponseDecoder
    , ResponseStatus(..)
    , unsigned
    )

{-| Internal representation of a request.
-}

import AWS.Internal.Body as Body exposing (Body)
import AWS.Internal.Service as Service exposing (Service)
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
--     | BadBody String -- Overloaded. Should introduce custom error type?


type alias ResponseDecoder a =
    ResponseStatus -> Metadata -> String -> Result Http.Error a


type ResponseStatus
    = GoodStatus_
    | BadStatus_


type alias Request a =
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
    -> Request a
unsigned name method uri body decoder =
    { name = name
    , method = method
    , path = uri
    , body = body
    , headers = []
    , query = []
    , decoder = decoder
    }
