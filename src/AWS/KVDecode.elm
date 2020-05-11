module AWS.KVDecode exposing
    ( KVDecoder, string, bool, int, float
    , object, field, optional, buildObject
    , Error(..), errorToString
    , decodeKVPairs
    , map
    )

{-| Blah.

@docs KVDecoder, string, bool, int, float

@docs object, field, optional, buildObject

@docs Error, errorToString

@docs decodeKVPairs

@docs map

-}

import Dict exposing (Dict)


type KVDecoder a
    = Val (String -> Result Error a)
    | Object (Dict String String -> Result Error a)


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



--=== Records


type ObjectDecoder a
    = ObjectDecoder (Dict String String -> Result Error a)


object : a -> ObjectDecoder a
object ctor =
    Ok ctor |> always |> ObjectDecoder


field : String -> KVDecoder f -> ObjectDecoder (f -> a) -> ObjectDecoder a
field name fdecoder (ObjectDecoder innerFieldFn) =
    case fdecoder of
        Val valFn ->
            ObjectDecoder
                (\dict ->
                    case Dict.get name dict of
                        Nothing ->
                            MissingField name |> Err

                        Just val ->
                            Result.map2 (\f x -> f x) (innerFieldFn dict) (valFn val)
                )

        Object objectFn ->
            ObjectDecoder (\dict -> Result.map2 (\f x -> f x) (innerFieldFn dict) (objectFn dict))


optional : String -> KVDecoder f -> ObjectDecoder (Maybe f -> a) -> ObjectDecoder a
optional name fdecoder (ObjectDecoder innerFieldFn) =
    case fdecoder of
        Val valFn ->
            ObjectDecoder
                (\dict ->
                    case Dict.get name dict of
                        Nothing ->
                            Result.map (\f -> f Nothing) (innerFieldFn dict)

                        Just val ->
                            Result.map2 (\f x -> f x) (innerFieldFn dict) (valFn val |> Result.map Just)
                )

        Object objectFn ->
            ObjectDecoder (\dict -> Result.map2 (\f x -> f x) (innerFieldFn dict) (objectFn dict |> Result.map Just))


buildObject : ObjectDecoder a -> KVDecoder a
buildObject (ObjectDecoder fieldFn) =
    Object fieldFn



--=== Map functions.


map : (a -> value) -> KVDecoder a -> KVDecoder value
map fn decoder =
    case decoder of
        Val valFn ->
            Val (valFn >> Result.map fn)

        Object objectFn ->
            Object (objectFn >> Result.map fn)



--=== KV Pair Decoding.


decodeKVPairs : KVDecoder a -> List ( String, String ) -> Result Error a
decodeKVPairs decoder pairs =
    let
        dict =
            Dict.fromList pairs
    in
    case decoder of
        Val val ->
            Failure "Failed to interpret a list of (String, String) pairs as a simple value." "" |> Err

        Object objectFn ->
            objectFn dict



--== Errors


type Error
    = Failure String String
    | MissingField String


errorToString : Error -> String
errorToString error =
    case error of
        Failure msg val ->
            msg ++ " " ++ val

        MissingField name ->
            "The " ++ name ++ " field is required but is missing."



-- Example to test compilation against.


type alias Example =
    { field : Int
    , inner : Inner
    }


type alias Inner =
    { a : String
    , b : Maybe String
    }


exampleDecoder : KVDecoder Example
exampleDecoder =
    object Example
        |> field "field" int
        |> field "inner" innerDecoder
        |> buildObject


innerDecoder : KVDecoder Inner
innerDecoder =
    object Inner
        |> field "a" string
        |> optional "b" string
        |> buildObject
