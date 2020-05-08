module AWS.Core.Request exposing
    ( Unsigned
    , queryString
    , unsigned
    , url
    )

import AWS.Core.Body as Body exposing (Body)
import AWS.Core.QueryString as QueryString
import AWS.Core.Service as Service exposing (Service)
import AWS.Core.Uri
import Http
import Json.Decode exposing (Decoder)


type alias Unsigned a =
    { name : String
    , method : String
    , path : String
    , body : Body
    , decoder : String -> Result String a
    , headers : List ( String, String )
    , query : List ( String, String )
    , responseParser : Maybe (Http.Response String -> Result Http.Error a)
    }


unsigned :
    String
    -> String
    -> String
    -> Body
    -> (String -> Result String a)
    -> Unsigned a
unsigned name method uri body decoder =
    Unsigned
        name
        method
        uri
        body
        decoder
        []
        []
        Nothing


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
                        qs |> QueryString.add (AWS.Core.Uri.percentEncode key) val
                    )
                    QueryString.empty
                |> QueryString.render
