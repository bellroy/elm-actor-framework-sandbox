module Sandbox.Components.Timer.Main exposing (Model, MsgIn(..), component, main, sandboxed)

import Expect
import Framework.Actor exposing (Component)
import Framework.Sandbox as Sandbox exposing (SandboxComponent)
import Framework.Sandbox.Browser as SandboxBrowser
import Framework.Sandbox.TestCase as TestCase
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Test.Html.Query as THQ
import Test.Html.Selector as THS
import Time


type alias Model =
    { start : Int
    , seconds : Int
    , isRunning : Bool
    }


type MsgIn
    = AddSeconds Int
    | RemoveSeconds Int
    | Start
    | Stop
    | Tick


component : Component Int Model MsgIn () (Html msg) msg
component =
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }


init : ( a, Int ) -> ( Model, List (), Cmd MsgIn )
init ( _, start ) =
    ( { start = start, seconds = start, isRunning = False }
    , []
    , Cmd.none
    )


update : MsgIn -> Model -> ( Model, List (), Cmd MsgIn )
update msgIn model =
    case msgIn of
        AddSeconds seconds ->
            ( { model | seconds = model.seconds + seconds }, [], Cmd.none )

        RemoveSeconds seconds ->
            ( { model | seconds = model.seconds - seconds }, [], Cmd.none )

        Start ->
            ( { model | isRunning = True }, [], Cmd.none )

        Stop ->
            ( { model | isRunning = False, seconds = model.start }, [], Cmd.none )

        Tick ->
            if model.seconds == 1 then
                update Stop model

            else
                update (RemoveSeconds 1) model


subscriptions : Model -> Sub MsgIn
subscriptions { isRunning } =
    if isRunning then
        Time.every 1000 (\_ -> Tick)

    else
        Sub.none


view : (MsgIn -> msg) -> Model -> a -> Html msg
view toSelf model _ =
    let
        styles =
            """
                .Timer { margin: 20px auto; padding: 20px; max-width: 400px; background-color: #444; color: #fff; font-family: monospace; font-size: 16px; display: flex; }
                .Timer span { display: block; flex: 1 0 auto; text-align: center; }
                .Timer button { background-color: transparent; border: 1px solid #fff; color: #fff; border-radius: 0; margin: 0 -1px; padding: 0 10px; }
            """
                |> Html.text
                |> List.singleton
                |> Html.node "style" []
    in
    Html.div [ HtmlA.class "Timer" ]
        [ styles
        , Html.span [] [ String.fromInt model.seconds |> Html.text ]
        , Html.button [ HtmlE.onClick (RemoveSeconds 10) ] [ Html.text "-10" ]
        , Html.button [ HtmlE.onClick (AddSeconds 10) ] [ Html.text "+10" ]
        , Html.button [ HtmlE.onClick Start ] [ Html.text "start" ]
        , Html.button [ HtmlE.onClick Stop ] [ Html.text "stop" ]
        ]
        |> Html.map toSelf



--


sandboxed : SandboxComponent Int Model MsgIn () (Html MsgIn)
sandboxed =
    component
        |> Sandbox.fromComponent 50
        |> Sandbox.addTestCase
            (TestCase.make
                { title = "Render"
                , description = "Renders the correct amount of seconds and has control buttons"
                , test =
                    \render _ model ->
                        render model
                            |> THQ.fromHtml
                            |> THQ.has
                                [ THS.text "60"
                                , THS.text "start"
                                , THS.text "stop"
                                , THS.text "-10"
                                , THS.text "+10"
                                ]
                }
                |> TestCase.setActions [ AddSeconds 10 ]
            )
        |> Sandbox.addTestCase
            (TestCase.make
                { title = "AddSeconds"
                , description = "Add 2 * 10 Seconds using two messages to a fresh Timer"
                , test = \_ a b -> Expect.equal (b.seconds - a.seconds) 20
                }
                |> TestCase.setActions [ AddSeconds 10, AddSeconds 10 ]
            )
        |> Sandbox.addTestCase
            (TestCase.make
                { title = "Tick"
                , description = "Completing a timer will reset it to it's original value"
                , test = \_ a b -> Expect.equal a.seconds b.seconds
                }
                |> TestCase.setActions (List.concat [ [ Start ], List.repeat 100 Tick ])
            )



--


main : SandboxBrowser.Program Int Model MsgIn () (Html MsgIn)
main =
    SandboxBrowser.document identity sandboxed
