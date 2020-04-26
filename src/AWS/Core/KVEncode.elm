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


type KVPairs
    = Pair String String
    | Pairs (List ( String, String ))
    | Skip


string : String -> String
string =
    identity


int : Int -> String
int =
    String.fromInt


float : Float -> String
float =
    String.fromFloat


bool : Bool -> String
bool val =
    if val then
        "true"

    else
        "false"


dict : Dict String a -> (a -> String) -> KVPairs
dict vals enc =
    Dict.foldr
        (\k v accum -> ( k, enc v ) :: accum)
        []
        vals
        |> Pairs


field : (a -> String) -> ( String, a ) -> KVPairs
field enc ( name, val ) =
    Pair name (enc val)


optional : (a -> String) -> ( String, Maybe a ) -> KVPairs
optional enc ( name, maybeVal ) =
    case maybeVal of
        Nothing ->
            Skip

        Just val ->
            Pair name (enc val)


denest : List ( String, String ) -> KVPairs
denest fields =
    Pairs fields


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
