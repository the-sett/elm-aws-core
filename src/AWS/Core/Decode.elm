module AWS.Core.Decode exposing (Metadata, Response, ResponseWrapper, ResultDecoder(..), dict, optional, required, responseWrapperDecoder)

{-| Helper functions for decoding AWS calls.


# Helpers

@docs Metadata, Response, ResponseWrapper, ResultDecoder, dict, optional, required, responseWrapperDecoder

-}

import Dict exposing (Dict)
import Json.Decode as JD
import Json.Decode.Pipeline as JDP


{-| A wrapped response
-}
type alias ResponseWrapper a =
    { response : Response a }


{-| A response consisting of data and meta-data.
-}
type alias Response a =
    { data : a
    , metadata : Metadata
    }


{-| Response meta-data.
-}
type alias Metadata =
    { requestId : String }


{-| Decoder type that can take a constant value or decode some string.
-}
type ResultDecoder a
    = ResultDecoder String (JD.Decoder a)
    | FixedResult a


{-| Decodes a ResponseWrapper.
-}
responseWrapperDecoder : String -> ResultDecoder a -> JD.Decoder (ResponseWrapper a)
responseWrapperDecoder actionName resultDecoder =
    JD.succeed ResponseWrapper
        |> JDP.required (actionName ++ "Response")
            (JD.succeed Response
                |> resultWrapperDecoder resultDecoder
                |> JDP.required "ResponseMetadata"
                    (JD.succeed Metadata
                        |> JDP.required "RequestId" JD.string
                    )
            )


resultWrapperDecoder : ResultDecoder a -> JD.Decoder (a -> b) -> JD.Decoder b
resultWrapperDecoder resultDecoder =
    case resultDecoder of
        ResultDecoder dataName dataDecoder ->
            JDP.required dataName dataDecoder

        FixedResult value ->
            JDP.hardcoded value



-- required and optional member decoders


{-| Tries to decode one of an set of field names against a decoder. If no
matching field succeeds with the decoder, the decoding will fail.
-}
required : List String -> JD.Decoder a -> JD.Decoder a
required fields decoder =
    tryFields fields decoder
        |> JD.andThen
            (\maybeValue ->
                case maybeValue of
                    Nothing ->
                        JD.fail ("Missing required fields with key of either: " ++ String.join ", " fields)

                    Just value ->
                        case JD.decodeValue decoder value of
                            Ok x ->
                                JD.succeed x

                            Err err ->
                                JD.fail (JD.errorToString err)
            )


{-| Tries to decode one of an optional set of field names against a decoder. If no
matching field succeeds with the decoder, Nothing will be decoded.
-}
optional : List String -> JD.Decoder a -> JD.Decoder (Maybe a)
optional fields decoder =
    tryFields fields decoder
        |> JD.andThen
            (\maybeValue ->
                case maybeValue of
                    Nothing ->
                        JD.succeed Nothing

                    Just value ->
                        case JD.decodeValue decoder value of
                            Ok x ->
                                JD.succeed (Just x)

                            Err err ->
                                JD.fail (JD.errorToString err)
            )


tryFields : List String -> JD.Decoder a -> JD.Decoder (Maybe JD.Value)
tryFields fields decoder =
    fields
        |> List.map (\field -> JD.field field JD.value)
        |> JD.oneOf
        |> JD.maybe



-- dict and helpers


{-| Decodes into a dict using either the standard Dict encoding as records of
"Name" and "Value" field pairs.
-}
dict : JD.Decoder a -> JD.Decoder (Dict String a)
dict valueDecoder =
    [ JD.dict valueDecoder
    , dictAsList valueDecoder
    ]
        |> JD.oneOf


dictAsList : JD.Decoder a -> JD.Decoder (Dict String a)
dictAsList valueDecoder =
    JD.list (nameValueDecoder valueDecoder)
        |> JD.map
            (List.map (\pair -> ( pair.name, pair.value ))
                >> Dict.fromList
            )


type alias NameValuePair a =
    { name : String
    , value : a
    }


nameValueDecoder : JD.Decoder a -> JD.Decoder (NameValuePair a)
nameValueDecoder valueDecoder =
    JD.succeed NameValuePair
        |> JDP.required "Name" JD.string
        |> JDP.required "Value" valueDecoder
