module Decoders exposing (..)

import Json.Decode exposing (..)


signatureDecoder constructor =
    map6 constructor
        (field "stem" string)
        (field "host" string)
        (field "credential" string)
        (field "date" string)
        (field "policy" string)
        (field "signature" string)


etagDecoder =
    field "ETag" string
