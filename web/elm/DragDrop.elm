module DragDrop exposing (dragDropEventHandlers)

import Html exposing (Attribute)
import Html.Events exposing (onWithOptions)
import Json.Decode as Json

import FileReader exposing (parseDroppedFiles, NativeFile)

dragDropEventHandlers : a -> a -> a -> (List NativeFile -> a) -> List (Attribute a)
dragDropEventHandlers enterMsg overMsg exitMsg dropMsg =
    [ onDragEnter enterMsg
    , onDragLeave exitMsg
    , onDragOver overMsg
    , onDrop dropMsg
    ]

-- Individual handler functions
-- Prevent default necessary to enable 'drop_ to be heard
onDragEnter : a -> Attribute a
onDragEnter =
  onDragFunctionIgnoreFiles "dragenter"

onDragOver : a -> Attribute a
onDragOver =
  onDragFunctionIgnoreFiles "dragover"

onDragLeave : a -> Attribute a
onDragLeave =
  onDragFunctionIgnoreFiles "dragleave"

onDrop : (List NativeFile -> a) -> Attribute a
onDrop dropMsg =
  onDragFunctionDecodeFiles "drop" dropMsg

onDragFunctionIgnoreFiles : String -> a -> Attribute a
onDragFunctionIgnoreFiles nativeEventName action =
    onWithOptions
        nativeEventName
        {stopPropagation = False, preventDefault = True}
        (Json.map (\_ -> action) Json.value)

onDragFunctionDecodeFiles : String -> (List NativeFile -> a) -> Attribute a
onDragFunctionDecodeFiles nativeEventName msgCreator =
    onWithOptions
        nativeEventName
        {stopPropagation = True, preventDefault = True}
        (Json.map msgCreator parseDroppedFiles)
