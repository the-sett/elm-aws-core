module AWS.KVDecode exposing
    ( KVDecoder
    , decodeKVPairs
    , string, bool, int, float
    , map
    , ObjectDecoder, object, field, optional, buildObject
    , Error(..), errorToString
    )

{-| KVDecode provides decoders to interpret lists of `(String, String)` into some
Elm type.

KVDecode is a counter-part to `AWS.KVEncode` but it has a cut down API. In
particular there is no scheme to number items into lists, or to nest field names
inside each other - only simple field names and a simple values are supported.
The reason for this is that AWS services may return values in header fields,
but only do this for relatively simple data models compared with the way in
which more complex encodings can be used to pass in arguments.


# Key-Value decoders.

@docs KVDecoder
@docs decodeKVPairs


# Simple values.

@docs string, bool, int, float


# Mapping over Key-Value decoders.

@docs map


# Decoding into records.

The term 'object' is used as the convention has been established by
`miniBill/elm-codec`.

@docs ObjectDecoder, object, field, optional, buildObject


# Error reporting when decoding fails.

@docs Error, errorToString

-}

import Dict exposing (Dict)


{-| The type of Key-Value decoders.
-}
type KVDecoder a
    = Val (String -> Result Error a)
    | Object (Dict String String -> Result Error a)


{-| Decodes a string value.
-}
string : KVDecoder String
string =
    Val (\val -> Ok val)


{-| Decodes a `Bool`value from "true" or "false".
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


{-| Decodes an `Int` value from a `String` or fails if the string is not an
integer.
-}
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


{-| Decodes an `Float` value from a `String` or fails if the string is not a
number.
-}
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


{-| A decoder of fields of named records.
-}
type ObjectDecoder a
    = ObjectDecoder (Dict String String -> Result Error a)


{-| Creates an object decoder from a record constructor.
-}
object : a -> ObjectDecoder a
object ctor =
    Ok ctor |> always |> ObjectDecoder


{-| Adds a mandatory field to an `ObjectDecoder`.
-}
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


{-| Adds an optional field to an `ObjectDecoder`.
-}
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


{-| Turns an `ObjectDecoder` into a `KVDecoder`.
-}
buildObject : ObjectDecoder a -> KVDecoder a
buildObject (ObjectDecoder fieldFn) =
    Object fieldFn



--=== Map functions.


{-| Maps over `KVDecoder`
-}
map : (a -> value) -> KVDecoder a -> KVDecoder value
map fn decoder =
    case decoder of
        Val valFn ->
            Val (valFn >> Result.map fn)

        Object objectFn ->
            Object (objectFn >> Result.map fn)



--=== KV Pair Decoding.


{-| Parses a list of Key-Value pairs as a strings into the Elm type described
by the decoder.

Errors may result if the decoder fails to match the data.

-}
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


{-| Describes the possible ways the Key-Value decoding can fail.
-}
type Error
    = Failure String String
    | MissingField String


{-| Converts an `Error` to `String` describing the error.
-}
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
