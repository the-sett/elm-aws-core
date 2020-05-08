module AWS.QueryString exposing
    ( QueryString
    , empty
    , render, add
    )

{-| This module exposes functions for working with query strings.
You can manipulate `QueryString`s:

> empty
> | |> add "a" "hello"
> | |> add "a" "goodbye"
> | |> add "b" "1"
> | |> render
> "?a=hello&a=goodbye&b=1" : String


## Types

@docs QueryString


## Constructing QueryStrings

@docs empty


## Manipulating parameters

@docs render, add

-}

import Dict exposing (Dict)
import String
import Url


{-| Represents a parsed query string.
-}
type QueryString
    = QueryString (Dict String (List String))


{-| Construct an empty QueryString.
-}
empty : QueryString
empty =
    QueryString Dict.empty


{-| Render a QueryString to a String.

> render (parse "?a=1&b=a&a=c")
> "?a=1&a=c&b=a" : String

-}
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


{-| Add a value to a key.

> parse "?a=1&b=a&a=c"
> | |> add "a" "2"
> | |> render
> "?a=2&a=1&a=c&b=a" : String
> parse "?a=1&b=a&a=c"
> | |> add "d" "hello"
> | |> render
> "?a=1&a=c&b=a&d=hello" : String

-}
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
