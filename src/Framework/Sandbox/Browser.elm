module Framework.Sandbox.Browser exposing (Program, document)

import Browser as ElmBrowser exposing (Document)
import Expect
import Framework.Actor as Actor
import Framework.Browser as Browser exposing (FrameworkModel)
import Framework.Internal.SandboxComponent as SandboxComponent exposing (SandboxComponent)
import Framework.Internal.TestCases.TestCase as TestCase exposing (TestCase)
import Framework.Internal.VirtualProgram as VirtualProgram exposing (VirtualProgram)
import Framework.Message as Message exposing (FrameworkMessage)
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Test.Runner as TestRunner


type alias Program appFlags componentModel componentMsgIn componentMsgOut output =
    Platform.Program () (DocumentModel appFlags componentModel componentMsgIn componentMsgOut output) (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output)


type DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output
    = MsgForFramework (FrameworkMessage appFlags () () componentModel componentMsgIn)
    | MsgForDocument (DocumentOperation appFlags componentModel componentMsgIn componentMsgOut output)


type DocumentOperation appFlags componentModel componentMsgIn componentMsgOut output
    = RunTestCase (TestCase appFlags componentModel componentMsgIn componentMsgOut output)


type alias DocumentModel appFlags componentModel componentMsgIn componentMsgOut output =
    { frameworkModel : FrameworkModel () componentModel
    , sandboxComponent : SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    }


document :
    (output -> Html (FrameworkMessage appFlags () () componentModel componentMsgIn))
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> Program appFlags componentModel componentMsgIn componentMsgOut output
document toHtml sandboxComponent =
    let
        virtualProgram =
            VirtualProgram.toVirtualProgram sandboxComponent

        updatedSandboxComponent =
            SandboxComponent.toTestCases sandboxComponent
                |> List.foldl
                    (\testCase ->
                        SandboxComponent.updateTestCase
                            (TestCase.setResult
                                (VirtualProgram.testTestCase
                                    virtualProgram
                                    testCase
                                )
                                testCase
                            )
                    )
                    sandboxComponent
    in
    ElmBrowser.document
        { init = always <| init virtualProgram updatedSandboxComponent
        , update = update virtualProgram
        , subscriptions = subscriptions virtualProgram
        , view = view toHtml virtualProgram
        }


init :
    VirtualProgram appFlags componentModel componentMsgIn output
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> ( DocumentModel appFlags componentModel componentMsgIn componentMsgOut output, Cmd (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output) )
init virtualProgram sandboxComponent =
    virtualProgram.init
        |> Tuple.mapFirst
            (\newFrameworkModel ->
                { frameworkModel = newFrameworkModel
                , sandboxComponent = sandboxComponent
                }
            )
        |> Tuple.mapSecond (Cmd.map MsgForFramework)


update :
    VirtualProgram appFlags componentModel componentMsgIn output
    -> DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output
    -> DocumentModel appFlags componentModel componentMsgIn componentMsgOut output
    -> ( DocumentModel appFlags componentModel componentMsgIn componentMsgOut output, Cmd (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output) )
update virtualProgram msg model =
    case msg of
        MsgForFramework frameworkMessage ->
            virtualProgram.update frameworkMessage model.frameworkModel
                |> Tuple.mapFirst
                    (\updatedFrameworkModel ->
                        { model | frameworkModel = updatedFrameworkModel }
                    )
                |> Tuple.mapSecond (Cmd.map MsgForFramework)

        MsgForDocument (RunTestCase testCase) ->
            ( { model
                | frameworkModel = VirtualProgram.runTestCase virtualProgram testCase |> Tuple.first
              }
            , Cmd.none
            )


subscriptions :
    VirtualProgram appFlags componentModel componentMsgIn output
    -> DocumentModel appFlags componentModel componentMsgIn componentMsgOut output
    -> Sub (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output)
subscriptions virtualProgram =
    .frameworkModel
        >> virtualProgram.subscriptions
        >> Sub.map MsgForFramework


view :
    (output -> Html (FrameworkMessage appFlags () () componentModel componentMsgIn))
    -> VirtualProgram appFlags componentModel componentMsgIn output
    -> DocumentModel appFlags componentModel componentMsgIn componentMsgOut output
    -> Document (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output)
view toHtml virtualProgram { frameworkModel, sandboxComponent } =
    let
        output =
            case Browser.getInstance frameworkModel.lastPid frameworkModel of
                Just componentModel ->
                    let
                        process =
                            virtualProgram.actor.apply componentModel
                    in
                    process.view frameworkModel.lastPid (always Nothing)
                        |> toHtml

                Nothing ->
                    Html.text ""
    in
    layout output sandboxComponent



---


layout :
    Html (FrameworkMessage appFlags () () componentModel componentMsgIn)
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> Document (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output)
layout outputHtml sandboxComponent =
    let
        newBody =
            List.append
                meta
                [ Html.div [ HtmlA.class "Layout" ]
                    [ Html.section [ HtmlA.class "Output" ] [ Html.map MsgForFramework outputHtml ]
                    , Html.section [ HtmlA.class "Info" ]
                        [ viewTestCases (SandboxComponent.toTestCases sandboxComponent)
                        ]
                    ]
                ]
    in
    { title = "Sandbox"
    , body = newBody
    }


viewTestCases :
    List (TestCase appFlags componentModel componentMsgIn componentMsgOut output)
    -> Html (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output)
viewTestCases =
    List.map viewTestCase
        >> Html.div [ HtmlA.class "container-fluid mt-3" ]


viewTestCase :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> Html (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output)
viewTestCase testCase =
    let
        ( statusClass, statusMessage ) =
            case TestCase.toResult testCase of
                Nothing ->
                    ( "dark", "" )

                Just expectation ->
                    case TestRunner.getFailureReason expectation of
                        Nothing ->
                            ( "success", "Test Passed" )

                        Just { given, description, reason } ->
                            ( "danger"
                            , "Test Failed: "
                                ++ Maybe.withDefault "" given
                                ++ " "
                                ++ description
                                ++ " ? "
                                ++ Debug.toString reason
                            )
    in
    Html.div [ HtmlA.class "card mb-3 text-white bg-dark" ]
        [ Html.div [ HtmlA.class "card-body" ]
            [ Html.h5 [ HtmlA.class "card-title" ]
                [ Html.text <| TestCase.toTitle testCase ]
            , Html.p [ HtmlA.class "card-text" ]
                [ Html.text <| TestCase.toDescription testCase ]
            , Html.button
                [ HtmlA.class "btn btn-outline-light"
                , HtmlE.onClick (MsgForDocument <| RunTestCase testCase)
                ]
                [ Html.text "Run this case" ]
            ]
        , if statusMessage /= "" then
            Html.div [ HtmlA.class ("card-footer bg-" ++ statusClass) ]
                [ Html.text statusMessage
                ]

          else
            Html.text ""
        ]


meta : List (Html msg)
meta =
    [ Html.node "link"
        [ HtmlA.rel "stylesheet"
        , HtmlA.href "https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/5.0.0-alpha1/css/bootstrap.min.css"
        ]
        []
    , stylesheet
    ]


stylesheet : Html msg
stylesheet =
    """
    html,body { height: 100%; margin: 0; padding: 0; }
    .Layout { display: flex; flex-direction: column; height: 100%; }
    .Output { min-height: 140px; height: 50%; overflow: auto; resize: vertical; border-bottom: 1px solid #444; background-size: 10px 10px; background-image: linear-gradient(to right, #E2F4FB 1px, transparent 1px), linear-gradient(to bottom, #E2F4FB 1px, transparent 1px); }
    .Info { flex: 1 1 auto; overflow: auto; background-color: var(--bs-gray-dark); }
    
    """
        |> Html.text
        |> List.singleton
        |> Html.node "style" [ HtmlA.type_ "text/css" ]
