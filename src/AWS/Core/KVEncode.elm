module AWS.Core.KVEncode exposing
    ( KVPairs
    , int, float, string, bool
    , dict
    , field, object
    )

{-| KVEncode provides encoders to turn things into list of `(String, String)`
which can be used to build headers or query parameters.


# Sets of KV String tuples.

@docs KVPairs


# Encoders for simple types and dicts.

@docs int, float, string, bool
@docs dict


# Encoders for records with optional fields or nesting.

@docs field, object

-}

import Dict exposing (Dict)


{-| Holds pairs of `(String, String)` tuples.

A field with a simple list of values:
Field.member.X

A field with a more complex list of values:
Field.member.X.InnerField

A field with a single complex value:
Field.InnerField

-}
type KVPairs
    = Val String
    | ListKVPairs (List KVPairs)
    | Object (List ( String, KVPairs ))


type Field
    = Pair String KVPairs
    | Skip


{-| Encodes a String (identity function).
-}
string : String -> KVPairs
string val =
    Val val


{-| Encodes an Int as a String.
-}
int : Int -> KVPairs
int val =
    String.fromInt val |> Val


{-| Encodes an Float as a String.
-}
float : Float -> KVPairs
float val =
    String.fromFloat val |> Val


{-| Encodes an Bool as a String ("true" or "false").
-}
bool : Bool -> KVPairs
bool val =
    if val then
        "true" |> Val

    else
        "false" |> Val


list : (a -> KVPairs) -> List a -> KVPairs
list enc vals =
    List.map enc vals |> ListKVPairs


{-| Combines a Dict with a String encoder for its values into a set of `KVPairs`.
-}
dict : (a -> KVPairs) -> Dict String a -> KVPairs
dict enc vals =
    -- Dict.foldr
    --     (\k v accum -> ( k, enc v ) :: accum)
    --     []
    --     vals
    --     |> Pairs
    Object []


{-| Encodes a pair of `(String, a)` into `KVPairs`.
-}
field : (a -> KVPairs) -> ( String, a ) -> Field
field enc ( name, val ) =
    Pair name (enc val)


{-| Encodes a pair of `(String, Maybe a)` into `KVPairs`.
-}
optional : (a -> KVPairs) -> ( String, Maybe a ) -> Field
optional enc ( name, maybeVal ) =
    case maybeVal of
        Nothing ->
            Skip

        Just val ->
            Pair name (enc val)


object : List Field -> KVPairs
object fields =
    List.foldr
        (\fld accum ->
            case fld of
                Pair name val ->
                    ( name, val ) :: accum

                Skip ->
                    accum
        )
        []
        fields
        |> Object



-- A field with a simple list of values:
-- Field.member.X
--
-- A field with a more complex list of values:
-- Field.member.X.InnerField
--
-- A field with a single complex value:
-- Field.InnerField


encode : KVPairs -> List ( String, String )
encode kvp =
    case kvp of
        Val _ ->
            []

        ListKVPairs vals ->
            []

        Object flds ->
            []



-- Example to test compilation against.


type alias Example =
    { field : List Inner
    , listField : List String
    , inner : Inner
    }


type alias Inner =
    { a : String
    , b : String
    }


encoder : Example -> KVPairs
encoder val =
    [ ( "field", val.field ) |> field (list innerEncoder)
    , ( "listField", val.listField ) |> field (list string)
    , ( "inner", val.inner ) |> field innerEncoder
    ]
        |> object


innerEncoder : Inner -> KVPairs
innerEncoder val =
    [ ( "a", val.a ) |> field string
    , ( "b", val.a ) |> field string
    ]
        |> object
