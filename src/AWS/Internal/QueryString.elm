module AWS.Internal.QueryString exposing (url)

import AWS.Internal.Request exposing (Unsigned)
import AWS.Service as Service exposing (Service)
import AWS.Uri
import Dict exposing (Dict)
import String
import Url


{-| Builds the URL for invoking a `Service` with a request.

This consists of combing together the host name, path and query string to form
the complete URL.

-}
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
                        qs |> add (AWS.Uri.percentEncode key) val
                    )
                    empty
                |> render


type QueryString
    = QueryString (Dict String (List String))


empty : QueryString
empty =
    QueryString Dict.empty


render : QueryString -> String
render (QueryString qs) =
    let
        flatten ( k, xs ) =
            List.map (\x -> k ++ "=" ++ Url.percentEncode x) xs
    in
    Dict.toList qs
        |> List.concatMap flatten
        |> String.join "&"
        |> (++) "?"


add : String -> String -> QueryString -> QueryString
add k v (QueryString qs) =
    let
        prepend maybeXs =
            case maybeXs of
                Nothing ->
                    Just [ v ]

                Just xs ->
                    Just (v :: xs)
    in
    Dict.update k prepend qs
        |> QueryString
