module DropZone exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on)
import Json.Decode as Json
import List as L
import FileReader exposing (..)
import DragDrop exposing (..)


type alias Model =
    { dnd : Int
    , nativeFiles : List NativeFile
    }


init =
    Model 0 []


type Msg
    = DragEnter
    | DragLeave
    | Drop (List NativeFile)
    | NoOp


update : Msg -> Model -> Model
update message model =
    case message of
        -- Reset ->
        --     init
        DragEnter ->
            { model | dnd = model.dnd + 1 }

        DragLeave ->
            { model | dnd = model.dnd - 1 }

        Drop nfs ->
            { model | dnd = 0, nativeFiles = nfs }

        NoOp ->
            model


view : String -> Model -> Html Msg
view instruction ({ nativeFiles, dnd } as model) =
    div
        (class "drop-zone-container" :: myHandlers)
        [ if dnd == 0 then
            text ""
          else
            div [ class "drop-zone" ] [ text "Drop" ]
        , h5 [] [ text instruction ]
        , ul [] <|
            L.map (\nf -> li [] [ text nf.name ]) nativeFiles
        , input
            [ type_ "file"
            , multiple True
            , onChangeFile
            ]
            [ text "Browse..." ]
        ]


myHandlers : List (Attribute Msg)
myHandlers =
    dragDropEventHandlers DragEnter NoOp DragLeave Drop


onChangeFile : Attribute Msg
onChangeFile =
    on "change"
        (Json.map Drop parseSelectedFiles)
