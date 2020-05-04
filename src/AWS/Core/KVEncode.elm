module AWS.Core.KVEncode exposing
    ( KVPairs
    , int, float, string, bool
    , dict
    , field, optional, denest, kvlist
    )

{-| KVEncode provides encoders to turn things into list of `(String, String)`
which can be used to build headers or query parameters.


# Sets of KV String tuples.

@docs KVPairs


# Encoders for simple types and dicts.

@docs int, float, string, bool
@docs dict


# Encoders for records with optional fields or nesting.

@docs field, optional, denest, kvlist

-}

import Dict exposing (Dict)


{-| Holds pairs of `(String, String)` tuples.
-}
type KVPairs
    = Pair String String
    | Pairs (List ( String, String ))
    | Skip


{-| Encodes a String (identity function).
-}
string : String -> String
string =
    identity


{-| Encodes an Int as a String.
-}
int : Int -> String
int =
    String.fromInt


{-| Encodes an Float as a String.
-}
float : Float -> String
float =
    String.fromFloat


{-| Encodes an Bool as a String ("true" or "false").
-}
bool : Bool -> String
bool val =
    if val then
        "true"

    else
        "false"



-- list :
--     (a -> List ( String, String ) -> List ( String, String ))
--     -> String
--     -> List a
--     -> List ( String, String )
--     -> List ( String, String )
-- list transform base values =
--     values
--         |> List.indexedMap
--             (\index rawValue ->
--                 transform rawValue []
--                     |> List.map
--                         (\( key, value ) ->
--                             ( listItemKey index base key
--                             , value
--                             )
--                         )
--             )
--         |> List.concat
--         |> List.append
--
--
-- listItemKey : Int -> String -> String -> String
-- listItemKey index base key =
--     base
--         ++ ".member."
--         ++ String.fromInt (index + 1)
--         ++ ("." ++ key)
--


{-| Combines a Dict with a String encoder for its values into a set of `KVPairs`.
-}
dict : (a -> String) -> Dict String a -> KVPairs
dict enc vals =
    Dict.foldr
        (\k v accum -> ( k, enc v ) :: accum)
        []
        vals
        |> Pairs


{-| Encodes a pair of `(String, a)` into `KVPairs`.
-}
field : (a -> String) -> ( String, a ) -> KVPairs
field enc ( name, val ) =
    Pair name (enc val)


{-| Encodes a pair of `(String, Maybe a)` into `KVPairs`.
-}
optional : (a -> String) -> ( String, Maybe a ) -> KVPairs
optional enc ( name, maybeVal ) =
    case maybeVal of
        Nothing ->
            Skip

        Just val ->
            Pair name (enc val)


{-| Nested lists of (String, String) pairs may result from inner objects,
this turns them into `KVPairs` that will be expanded into a flattened list.
-}
denest : List ( String, String ) -> KVPairs
denest fields =
    Pairs fields


{-| Lists sets of `KVPairs` into a flattened list of `(String, String)` pairs.
-}
kvlist : List KVPairs -> List ( String, String )
kvlist fields =
    List.foldr
        (\fld accum ->
            case fld of
                Pair name val ->
                    ( name, val ) :: accum

                Pairs pairs ->
                    List.append pairs accum

                Skip ->
                    accum
        )
        []
        fields
