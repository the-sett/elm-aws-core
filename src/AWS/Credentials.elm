module AWS.Credentials exposing
    ( Credentials, AccessKeyId, SecretAccessKey
    , fromAccessKeys, withSessionToken
    )

{-| A set of AWS credentials consists of an acces key id, a secret access key and
an optional session token.

@docs Credentials, AccessKeyId, SecretAccessKey
@docs fromAccessKeys, withSessionToken

-}

-- CREDENTIALS


{-| Holds AWS credentials.
-}
type alias Credentials =
    { accessKeyId : String
    , secretAccessKey : String
    , sessionToken : Maybe String
    }


{-| The AWS access key ID.
-}
type alias AccessKeyId =
    String


{-| The AWS secret access key.
-}
type alias SecretAccessKey =
    String


{-| Create AWS credentials given an access key and secret key.
-}
fromAccessKeys : AccessKeyId -> SecretAccessKey -> Credentials
fromAccessKeys keyId secretKey =
    { accessKeyId = keyId
    , secretAccessKey = secretKey
    , sessionToken = Nothing
    }


{-| Sets the session token.
-}
withSessionToken : String -> Credentials -> Credentials
withSessionToken token creds =
    { creds | sessionToken = Just token }
