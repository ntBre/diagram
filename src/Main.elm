module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Debug
import String
import List
import List.Extra
import Array

-- MAIN

main =
  Browser.element
      { init = init
      , view = view
      , update = update
      , subscriptions = subscriptions
      }

-- MODEL

type alias Caption =
    { text: String
    , size: String
    , position: String
    }

toRow: Int -> Caption -> Html Msg
toRow id cap =
    tr []
        [ td [] [text cap.text]
        , td [] [text cap.size]
        , td [] [text cap.position]
        , td [] [button [onClick (EditCap id)] [ text "edit" ]]
        , td [] [button [onClick (CopyCap id)] [ text "copy" ]]
        , td [] [button [onClick (RemoveCap id)] [ text "del" ]]
        ]

type alias Model =
    { image : String
    , gridx : String
    , gridy : String
    , oldGridx : String
    , oldGridy : String
    , text : String
    , size : String
    , position: String
    , oldText : String
    , oldSize : String
    , oldPosition: String
    , captions: List Caption
    , holdCapfile : String
    , capfile : String
    , lx : String
    , uy : String
    , rx : String
    , by : String
    , olx : String
    , ouy : String
    , orx : String
    , oby : String
    }

type alias Flags =
    { img: String
    , caps: List Caption
    , capfile: String
    }

init : Flags -> (Model, Cmd Msg)
init flags =
    let mod =
            { image = flags.img
            , gridx = ""
            , gridy = ""
            , oldGridx = ""
            , oldGridy = ""
            , text = ""
            , size = ""
            , position = ""
            , oldText = ""
            , oldSize = ""
            , oldPosition = ""
            , captions = flags.caps
            , holdCapfile = flags.capfile
            , capfile = ""
            , lx = ""
            , uy = ""
            , rx = ""
            , by = ""
            , olx = ""
            , ouy = ""
            , orx = ""
            , oby = ""
            }
    in if List.length mod.captions > 0
       then (mod, addCaption mod)
       else (mod, Cmd.none)

-- UPDATE

type Msg
    = Grid
    | ClearGrid
    | AddCap
    | EditCap Int
    | CopyCap Int
    | ChangeCapfile String
    | DumpCaps
    | RemoveCap Int
    | GotImg (Result Http.Error String)
    | Changelx String
    | Changeuy String
    | Changerx String
    | Changeby String
    | DoCrop
    | ChangeX String
    | ChangeY String
    | ChangeText String
    | ChangeSize String
    | ChangePosition String
    | Success (Result Http.Error ())

popCap : Model -> Int -> Maybe Model
popCap model id =
    let myCap = Array.get id (Array.fromList model.captions)
    in case myCap of
            Nothing -> Nothing
            Just cap ->
                    Just {model
                        | captions = List.Extra.removeAt id model.captions
                        , text = cap.text
                        , size = cap.size
                        , position = cap.position
                    }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Changelx s -> ({model | lx = s}, Cmd.none)
        Changeuy s -> ({model | uy = s}, Cmd.none)
        Changerx s -> ({model | rx = s}, Cmd.none)
        Changeby s -> ({model | by = s}, Cmd.none)
        DoCrop ->
            if model.lx == "" ||
                model.uy == "" ||
                    model.rx == "" ||
                        model.by == ""
            then (model, Cmd.none)
            else let newMod = 
                        { model
                            | olx = model.lx
                            , ouy = model.uy
                            , orx = model.rx
                            , oby = model.by
                              -- uncomment to keep old values out of boxes
                            -- , lx = ""
                            -- , uy = ""
                            -- , rx = ""
                            -- , by = ""
                        }
                    in ( newMod, doCrop newMod)
        Success _ -> (model, Cmd.none)
        DumpCaps -> (model, dumpCaps {model | capfile = model.holdCapfile})
        ChangeCapfile file ->
            ({ model | holdCapfile = file }, Cmd.none)
        CopyCap id ->
            let myCap = Array.get id (Array.fromList model.captions)
            in case myCap of
                    Nothing ->
                        (model, Cmd.none)
                    Just cap ->
                        let mod = {model
                                      | text = cap.text
                                      , size = cap.size
                                      , position = cap.position
                                  }
                        in (mod, addCaption mod)
        EditCap id ->
            let newMod = popCap model id
            in case newMod of
                   Nothing -> (model, Cmd.none)
                   Just mod -> ( mod, addCaption mod )
        RemoveCap id ->
            let newMod = 
                    {model | captions =
                        List.Extra.removeAt id model.captions
                    }
            in ( newMod ,
                  addCaption newMod )
        AddCap ->
            if model.text == "" ||
                model.size == "" ||
                    model.position == ""
            then
                (model, Cmd.none )
            else
                let newMod =
                        { model | captions =
                              { text = model.text
                              , size = model.size
                              , position = model.position
                              } :: model.captions
                        , oldText = model.text
                        , oldSize = model.size
                        , oldPosition = model.position
                        , text = ""
                        , size = ""
                        , position = ""
                        }
                    in ( newMod , addCaption newMod )
        ChangeText newText ->
            ( { model | text = newText }, Cmd.none )
        ChangeSize newText ->
            ( { model | size = newText }, Cmd.none )
        ChangePosition newText ->
            ( { model | position = newText }, Cmd.none )
        ChangeX newX ->
            ( { model | gridx = newX }, Cmd.none )
        ChangeY newY ->
            ( { model | gridy = newY }, Cmd.none )
        Grid ->
            if model.gridx == "" ||
                model.gridy == ""
            then
                (model, Cmd.none)
            else
                let newMod = 
                        { model | image = model.image
                        , oldGridx = model.gridx
                        , oldGridy = model.gridy
                        , gridx = ""
                        , gridy = ""
                        }
                    in ( newMod, addGrid newMod)
        ClearGrid ->
                let newMod = 
                        { model | image = model.image
                        , oldGridx = ""
                        , oldGridy = ""
                        , gridx = ""
                        , gridy = ""
                        }
                    in ( newMod, addGrid newMod)
        GotImg result ->
            case result of
                Ok img ->
                    ( {model | image = img}, Cmd.none)
                Err _ ->
                    (model, Cmd.none)

-- VIEW

size : Int -- size in px of the input boxes
size = 50

view : Model -> Html Msg
view model =
  div []
    [ div [style "float" "left"] [ img [src model.image] [] ]
    , div [style "float" "left"]
        [ div []
              [ input [ placeholder "grid h"
                      , value model.gridx
                      , style "width" (String.fromInt (2*size) ++ "px"), onInput ChangeX ] []
              , input [ placeholder "grid v"
                      , value model.gridy
                      , style "width" (String.fromInt (2*size) ++ "px"), onInput ChangeY ] []
              , button [ onClick Grid ] [ text "grid" ]
              , button [ onClick ClearGrid ] [ text "clear" ]
              ]
        , div []
            [ input [ placeholder "lx", style "width" (String.fromInt size ++ "px")
                    , value model.lx
                    , onInput Changelx ] []
            , input [ placeholder "uy", style "width" (String.fromInt size ++ "px")
                    , value model.uy
                    , onInput Changeuy ] []
            , input [ placeholder "rx", style "width" (String.fromInt size ++ "px")
                    , value model.rx
                    , onInput Changerx ] []
            , input [ placeholder "by", style "width" (String.fromInt size ++ "px")
                    , value model.by
                    , onInput Changeby ] []
            , button [onClick DoCrop] [ text "crop" ]
            ]
        , div []
            [ input [ placeholder "Text"
                    , value model.text
                    , style "width" (String.fromInt (4*size//3) ++ "px")
                    , onInput ChangeText ] []
            , input [ placeholder "Size"
                    , value model.size
                    , style "width" (String.fromInt (4*size//3) ++ "px")
                    , onInput ChangeSize ] []
            , input [ placeholder "Position"
                    , value model.position
                    , style "width" (String.fromInt (4*size//3 + 1) ++ "px")
                , onInput ChangePosition ] []
        , button [onClick AddCap] [ text "add caption" ]
        ]
        , table []
            ([ thead []
                   [ th [] [text "Text"]
                   , th [] [text "Size"]
                   , th [] [text "x,y"]
                   ]
             ]
                 ++ List.indexedMap toRow model.captions
            )
        , div []
            [ input [ placeholder "caption file"
                    , value model.holdCapfile
                    , style "width" (String.fromInt (4*size) ++ "px")
                    , onInput ChangeCapfile ] []
            , button [onClick DumpCaps] [ text "save caption file" ]
        ]
        ]
    ]
      
-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none

-- HTTP
reqURL : Model -> String
reqURL model =
    "http://localhost:8080/req?" ++ (gridStr model)
        ++ "&" ++ (capStr model) ++ "&dump=" ++ model.capfile
        ++ "&crop=" ++ (cropStr model)

cropStr : Model -> String
cropStr model =
    model.olx ++ "," ++ model.ouy ++ "," ++ model.orx ++ "," ++ model.oby

gridStr : Model -> String
gridStr model =
        "grid=" ++ model.oldGridx ++ "," ++ model.oldGridy

capStr : Model -> String
capStr model =
    List.foldr
    (\cap str -> str ++ cap.text ++ "," ++ cap.size ++ "," ++ cap.position ++ "&cap=")
    "cap=" model.captions

addGrid : Model -> Cmd Msg
addGrid model =
    Http.get
        { url = reqURL model
        , expect = Http.expectString GotImg
        }

addCaption : Model -> Cmd Msg
addCaption model =
    Http.get
        { url = reqURL model
        , expect = Http.expectString GotImg
        }

dumpCaps : Model -> Cmd Msg
dumpCaps model =
    Http.get
        { url = reqURL model
        , expect = Http.expectWhatever Success
        }

doCrop : Model -> Cmd Msg
doCrop model =
    Http.get
        { url = reqURL model
        , expect = Http.expectString GotImg
        }
