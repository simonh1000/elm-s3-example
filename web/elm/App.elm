module App exposing (init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task exposing (Task)
import Http exposing (..)
import Json.Encode as E exposing (Value)
import Json.Decode as Json
import List as L
import Decoders exposing (..)
import DropZone as DZ
import FileReader as FR exposing (readAsArrayBuffer, NativeFile)


-- MODEL


type alias Model =
    { msg : String
    , signingData : SigningData
    , dropzone : DZ.Model
    }


type alias SigningData =
    { stem : String
    , host : String
    , credential : String
    , date : String
    , policy : String
    , signature : String
    }


initSigningData =
    SigningData "" "" "" "" "" ""


init : ( Model, Cmd Msg )
init =
    ( Model "" initSigningData DZ.init, Cmd.none )



-- UPDATE


type Msg
    = SendToS3
    | DZMsg DZ.Msg
    | SigningDataResult (Result Http.Error SigningData)
    | S3Confirmation (Result String String)


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        SendToS3 ->
            { model | msg = "Getting Authorisation" } ! [ getSigningData ]

        DZMsg msg ->
            { model | dropzone = DZ.update msg model.dropzone } ! []

        SigningDataResult res ->
            case res of
                Ok data ->
                    let
                        newModel =
                            { model | signingData = data, msg = "Contacting S3" }
                    in
                        newModel ! [ sendSignedData newModel ]

                Err err ->
                    { model | msg = toString err } ! []

        S3Confirmation res ->
            case res of
                Ok v ->
                    { model | msg = "File saved" } ! []

                Err err ->
                    { model | msg = toString err } ! []



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "container" ]
        [ h1 [] [ text "S3 test" ]
        , DZ.view "Drop here" model.dropzone |> Html.map DZMsg
        , div []
            [ button
                [ class "btn btn-default"
                , onClick SendToS3
                ]
                [ text "Upload to S3" ]
            ]
        , p [] [ text <| toString model.msg ]
        , p [] [ text <| toString model.signingData ]
        ]


getSigningData =
    Http.get "/api/signature" (signatureDecoder SigningData)
        |> Http.send SigningDataResult


sendSignedData : Model -> Cmd Msg
sendSignedData { signingData, dropzone } =
    case dropzone.nativeFiles of
        [] ->
            Cmd.none

        nf :: _ ->
            request
                { method = "POST"
                , headers = []
                , url = "http://mpower-test.s3.amazonaws.com"
                , body = makeMultiPart signingData nf
                , expect = expectJson (Json.field "ETag" Json.string)
                , timeout = Nothing
                , withCredentials = False
                }
                |> Http.toTask
                |> Task.mapError toString
                |> Task.map Result.Ok
                |> Task.onError (\s -> Task.succeed (Result.Err s))
                |> Task.perform S3Confirmation


makeMultiPart : SigningData -> FR.NativeFile -> Http.Body
makeMultiPart signingData nf =
    [ stringPart "key" (signingData.stem ++ "/" ++ nf.name)
    , stringPart "x-amz-algorithm" "AWS4-HMAC-SHA256"
    , stringPart "x-amz-credential" signingData.credential
    , stringPart "x-amz-date" signingData.date
    , stringPart "success_action_redirect" (signingData.host ++ "/success")
    , stringPart "policy" signingData.policy
    , stringPart "x-amz-signature" signingData.signature
    , FR.filePart "file" nf
    ]
        |> multipartBody



-- sendSignedData : Model -> Cmd Msg
-- sendSignedData {signingData, dropzone} =
--     let
--         blobString =
--             L.head dropzone.nativeFiles
--             |> Debug.log "blobString1"
--             |> Maybe.map (\nf -> E.encode 0 nf.blob)
--             |> Debug.log "blobString2"
--             |> Maybe.withDefault "no file present"
--         parts =
--             [ stringPart "key" (signingData.stem ++ "/testfile.txt")
--             , stringPart "x-amz-algorithm" "AWS4-HMAC-SHA256"
--             , stringPart "x-amz-credential" signingData.credential
--             , stringPart "x-amz-date" signingData.date
--             , stringPart "success_action_redirect" (signingData.host ++ "/success")
--             , stringPart "policy" signingData.policy
--             , stringPart "x-amz-signature" signingData.signature
--             , stringPart "file" blobString
--             ]
--             |> multipartBody
--         req =
--             request
--                 { method = "POST"
--                 , headers = []
--                 , url = "http://mpower-test.s3.amazonaws.com"
--                 , body = parts
--                 , expect = expectJson (Json.field "ETag" Json.string)
--                 , timeout = Nothing
--                 , withCredentials = False
--                 }
--     in
--     send S3Confirmation req
--
