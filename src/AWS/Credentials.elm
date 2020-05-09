module AWS.Credentials exposing
    ( Credentials, AccessKeyId, SecretAccessKey, SessionToken
    , fromAccessKeys, setSessionToken
    )

{-| AWS credentials.

A set of AWS credentials consists of an acces key id, a secret access key and
an optional session token.

@docs Credentials, AccessKeyId, SecretAccessKey, SessionToken
@docs fromAccessKeys, setSessionToken

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


{-| An optional AWS session token.
-}
type alias SessionToken =
    String


{-| Create AWS credentials given an access key and secret key.
-}
fromAccessKeys : AccessKeyId -> SecretAccessKey -> Credentials
fromAccessKeys keyId secretKey =
    { accessKeyId = keyId
    , secretAccessKey = secretKey
    , sessionToken = Nothing
    }


{-| Set the session token.
-}
setSessionToken : SessionToken -> Credentials -> Credentials
setSessionToken token creds =
    { creds | sessionToken = Just token }
