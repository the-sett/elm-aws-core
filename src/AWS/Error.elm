module AWS.Error exposing (..)

-- Decodes from AWS responses like this:
-- { "__type":"PasswordResetRequiredException"
-- , "message":"Password reset required for the user"
-- }


type alias AWSError a =
    { error : a
    , message : String
    }
