module App exposing (init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task exposing (Task)
import Http exposing (..)
import List as L
import Json.Decode as Json
import Decoders exposing (..)
import FileReader as FR exposing (readAsArrayBuffer, NativeFile, parseSelectedFiles)
import DragDrop exposing (..)


-- MODEL


bucket =
    "http://test.s3.amazonaws.com"


type alias Model =
    { msg : String
    , signingData : SigningData
    , dnd : Int
    , nativeFiles : List NativeFile
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
    ( Model "" initSigningData 0 [], Cmd.none )



-- UPDATE


type Msg
    = DragEnter
    | DragLeave
    | Drop (List NativeFile)
    | NoOp
    | SendToS3
    | SigningDataResult (Result Http.Error SigningData)
    | S3Confirmation (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        DragEnter ->
            { model | dnd = model.dnd + 1 } ! []

        DragLeave ->
            { model | dnd = model.dnd - 1 } ! []

        Drop nfs ->
            { model | dnd = 0, nativeFiles = nfs } ! []

        NoOp ->
            model ! []

        SendToS3 ->
            { model | msg = "Getting Authorisation" } ! [ getSigningData ]

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
        , dzView model
        , div []
            [ button
                [ class "btn btn-primary"
                , onClick SendToS3
                ]
                [ text "Upload to S3" ]
            ]
        , p [] [ text model.msg ]
        , p [] [ text <| toString model.signingData ]
        ]


dzView : Model -> Html Msg
dzView { nativeFiles, dnd } =
    let
        styles =
            style
                [ ( "height", "200px" )
                , ( "border"
                  , "3px dotted "
                        ++ if dnd == 0 then
                            "blue"
                           else
                            "red"
                  )
                , ( "margin-bottom", "15px" )
                , ( "padding", "15px" )
                ]
    in
        div
            (styles :: myHandlers)
            [ h4 [] [ text "Drop here" ]
            , input
                [ type_ "file"
                , multiple True
                , onChangeFile
                ]
                [ text "Browse..." ]
            , ul [] <|
                L.map (\nf -> li [] [ text nf.name ]) nativeFiles
            ]


myHandlers : List (Attribute Msg)
myHandlers =
    dragDropEventHandlers DragEnter NoOp DragLeave Drop


onChangeFile : Attribute Msg
onChangeFile =
    on "change"
        (Json.map Drop parseSelectedFiles)



--


getSigningData : Cmd Msg
getSigningData =
    Http.get "/api/signature" (signatureDecoder SigningData)
        |> Http.send SigningDataResult


sendSignedData : Model -> Cmd Msg
sendSignedData { signingData, nativeFiles } =
    case nativeFiles of
        [] ->
            Cmd.none

        nf :: _ ->
            request
                { method = "POST"
                , headers = []
                , url = bucket
                , body = makeMultiPart signingData nf
                , expect = expectJson etagDecoder
                , timeout = Nothing
                , withCredentials = False
                }
                |> Http.send S3Confirmation


makeMultiPart : SigningData -> FR.NativeFile -> Http.Body
makeMultiPart signingData nf =
    multipartBody
        [ stringPart "key" (signingData.stem ++ "/" ++ nf.name)
        , stringPart "x-amz-algorithm" "AWS4-HMAC-SHA256"
        , stringPart "x-amz-credential" signingData.credential
        , stringPart "x-amz-date" signingData.date
        , stringPart "success_action_redirect" (signingData.host ++ "/success")
        , stringPart "policy" signingData.policy
        , stringPart "x-amz-signature" signingData.signature
        , FR.filePart "file" nf
        ]
