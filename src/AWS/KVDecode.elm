module AWS.KVDecode exposing
    ( KVDecoder, string, bool, int, float
    , field, optional
    , Error(..), errorToString
    -- , map, map2, map3, map4, map5, map6, map7, map8
    -- , list, dict, keyValuePairs, oneOrMore
    -- , at, index
    -- , maybe, oneOf
    -- , decodeKVPairs,
    -- , lazy, null, succeed, fail, andThen
    )

{-| Blah.

@docs KVDecoder, string, bool, int, float

@docs list, dict, keyValuePairs, oneOrMore

@docs field, optional, at, index

@docs maybe, oneOf

@docs decodeKVPairs, Error, errorToString

@docs map, map2, map3, map4, map5, map6, map7, map8

@docs lazy, null, succeed, fail, andThen

-}

import Array exposing (Array)
import Dict exposing (Dict)
import Json.Encode


type KVDecoder a
    = Val (String -> Result Error a)
    | Field String (KVDecoder a)


{-| Decodes a string value.
-}
string : KVDecoder String
string =
    Val (\val -> Ok val)


{-| Decodes a bool value from "true" or "false".
-}
bool : KVDecoder Bool
bool =
    Val
        (\val ->
            case val of
                "true" ->
                    Ok True

                "false" ->
                    Ok False

                _ ->
                    Failure "Failed to interpret as a Bool the value: " val |> Err
        )


int : KVDecoder Int
int =
    Val
        (\val ->
            case String.toInt val of
                Just intVal ->
                    Ok intVal

                Nothing ->
                    Failure "Failed to interpret as an Int the value: " val |> Err
        )


float : KVDecoder Float
float =
    Val
        (\val ->
            case String.toFloat val of
                Just floatVal ->
                    Ok floatVal

                Nothing ->
                    Failure "Failed to interpret as a Float the value: " val |> Err
        )



-- list : KVDecoder a -> KVDecoder (List a)
-- list =
--     Debug.todo "work in progress"
--
--
-- dict : KVDecoder a -> KVDecoder (Dict String a)
-- dict =
--     Debug.todo "work in progress"
--=== Records


type ObjectDecoder a
    = ObjectDecoder (KVDecoder a)


object : a -> ObjectDecoder a
object ctor =
    succeed ctor |> ObjectDecoder


field : String -> KVDecoder f -> ObjectDecoder (f -> a) -> ObjectDecoder a
field name fdecoder odecoder =
    case odecoder of
        ObjectDecoder nextDecoder ->
            ObjectDecoder (map2 (\f x -> f x) nextDecoder (Field name fdecoder))


optional : String -> KVDecoder f -> ObjectDecoder (Maybe f -> a) -> ObjectDecoder a
optional name fdecoder odecoder =
    case odecoder of
        ObjectDecoder nextDecoder ->
            ObjectDecoder (map2 (\f x -> f x) nextDecoder (Field name (maybe fdecoder)))


maybe : KVDecoder a -> KVDecoder (Maybe a)
maybe decoder =
    case decoder of
        Val fn ->
            Val (fn >> Result.map Just)

        Field name innerDecoder ->
            Field name (maybe innerDecoder)


buildObject : ObjectDecoder a -> KVDecoder a
buildObject (ObjectDecoder decoder) =
    decoder



--===
-- keyValuePairs : KVDecoder a -> KVDecoder (List ( String, a ))
-- keyValuePairs =
--     Debug.todo "work in progress"
--
--
-- oneOrMore : (a -> List a -> value) -> KVDecoder a -> KVDecoder value
-- oneOrMore =
--     Debug.todo "work in progress"
--
--
-- at : List String -> KVDecoder a -> KVDecoder a
-- at =
--     Debug.todo "work in progress"
--
--
-- index : Int -> KVDecoder a -> KVDecoder a
-- index =
--     Debug.todo "work in progress"
--
--
-- oneOf : List (KVDecoder a) -> KVDecoder a
-- oneOf =
--     Debug.todo "work in progress"


map : (a -> value) -> KVDecoder a -> KVDecoder value
map fn decoder =
    case decoder of
        Val valFn ->
            Val (valFn >> Result.map fn)

        Field name innerDecoder ->
            Field name (map fn innerDecoder)


map2 : (a -> b -> value) -> KVDecoder a -> KVDecoder b -> KVDecoder value
map2 fn first second =
    case ( first, second ) of
        ( Val valFn1, Val valFn2 ) ->
            Val (\a b -> Result.map2 fn (valFn1 a) (valFn2 b))



-- Field name innerDecoder ->
--     Field name (map2 fn innerDecoder second)
-- map3 : (a -> b -> c -> value) -> KVDecoder a -> KVDecoder b -> KVDecoder c -> KVDecoder value
-- map3 =
--     Debug.todo "work in progress"
--
--
-- map4 : (a -> b -> c -> d -> value) -> KVDecoder a -> KVDecoder b -> KVDecoder c -> KVDecoder d -> KVDecoder value
-- map4 =
--     Debug.todo "work in progress"
--
--
-- map5 : (a -> b -> c -> d -> e -> value) -> KVDecoder a -> KVDecoder b -> KVDecoder c -> KVDecoder d -> KVDecoder e -> KVDecoder value
-- map5 =
--     Debug.todo "work in progress"
--
--
-- map6 : (a -> b -> c -> d -> e -> f -> value) -> KVDecoder a -> KVDecoder b -> KVDecoder c -> KVDecoder d -> KVDecoder e -> KVDecoder f -> KVDecoder value
-- map6 =
--     Debug.todo "work in progress"
--
--
-- map7 : (a -> b -> c -> d -> e -> f -> g -> value) -> KVDecoder a -> KVDecoder b -> KVDecoder c -> KVDecoder d -> KVDecoder e -> KVDecoder f -> KVDecoder g -> KVDecoder value
-- map7 =
--     Debug.todo "work in progress"
--
--
-- map8 : (a -> b -> c -> d -> e -> f -> g -> h -> value) -> KVDecoder a -> KVDecoder b -> KVDecoder c -> KVDecoder d -> KVDecoder e -> KVDecoder f -> KVDecoder g -> KVDecoder h -> KVDecoder value
-- map8 =
--     Debug.todo "work in progress"


decodeKVPairs : KVDecoder a -> List ( String, String ) -> Result Error a
decodeKVPairs decoder pairs =
    Debug.todo "work in progress"


type Error
    = Failure String String
    | MissingField



-- | Field String Error
-- | Index Int Error
-- | OneOf (List Error)


errorToString : Error -> String
errorToString =
    Debug.todo "work in progress"


succeed : a -> KVDecoder a
succeed val =
    Val (\_ -> Ok val)



--
--
-- fail : String -> KVDecoder a
-- fail =
--     Debug.todo "work in progress"
-- andThen : (a -> KVDecoder b) -> KVDecoder a -> KVDecoder b
-- andThen =
--     Debug.todo "work in progress"
-- lazy : (() -> KVDecoder a) -> KVDecoder a
-- lazy =
--     Debug.todo "work in progress"
--
--
-- null : a -> KVDecoder a
-- null =
--     Debug.todo "work in progress"
