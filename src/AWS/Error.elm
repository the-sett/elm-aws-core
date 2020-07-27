module AWS.Error exposing (..)


type alias AWSError a =
    { error : a
    , message : String
    }
