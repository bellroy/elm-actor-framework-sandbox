module Framework.Sandbox.Internal.Browser exposing (Program, document)

import Browser as ElmBrowser exposing (Document)
import Framework.Sandbox.Internal.SandboxComponent as SandboxComponent exposing (SandboxComponent)
import Framework.Sandbox.Internal.TestCases.TestCase as TestCase exposing (TestCase)
import Framework.Sandbox.Internal.VirtualProgram as VirtualProgram exposing (VirtualProgram)
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Test.Runner as TestRunner


type alias Program appFlags componentModel componentMsgIn componentMsgOut output =
    Platform.Program () (DocumentModel appFlags componentModel componentMsgIn componentMsgOut output) (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output)


type DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output
    = MsgForComponent componentMsgIn
    | MsgForDocument (DocumentOperation appFlags componentModel componentMsgIn componentMsgOut output)


type DocumentOperation appFlags componentModel componentMsgIn componentMsgOut output
    = RunTestCase (TestCase appFlags componentModel componentMsgIn componentMsgOut output)


type alias DocumentModel appFlags componentModel componentMsgIn componentMsgOut output =
    { componentModel : componentModel
    , sandboxComponent : SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    , prependHtml : List (Html Never)
    }


document :
    (output -> Html componentMsgIn)
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
    VirtualProgram appFlags componentModel componentMsgIn componentMsgOut output
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> ( DocumentModel appFlags componentModel componentMsgIn componentMsgOut output, Cmd (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output) )
init virtualProgram sandboxComponent =
    virtualProgram.init (always []) Nothing
        |> Tuple.mapFirst
            (\componentModel ->
                { componentModel = componentModel
                , sandboxComponent = sandboxComponent
                , prependHtml = []
                }
            )
        |> Tuple.mapSecond (Cmd.map MsgForComponent)


update :
    VirtualProgram appFlags componentModel componentMsgIn componentMsgOut output
    -> DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output
    -> DocumentModel appFlags componentModel componentMsgIn componentMsgOut output
    -> ( DocumentModel appFlags componentModel componentMsgIn componentMsgOut output, Cmd (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output) )
update virtualProgram msg model =
    case msg of
        MsgForComponent frameworkMessage ->
            virtualProgram.update (always []) frameworkMessage model.componentModel
                |> Tuple.mapFirst
                    (\updatedFrameworkModel ->
                        { model | componentModel = updatedFrameworkModel }
                    )
                |> Tuple.mapSecond (Cmd.map MsgForComponent)

        MsgForDocument (RunTestCase testCase) ->
            ( { model
                | componentModel =
                    VirtualProgram.runTestCase virtualProgram testCase
                        |> Tuple.second
              }
            , Cmd.none
            )


subscriptions :
    VirtualProgram appFlags componentModel componentMsgIn componentMsgOut output
    -> DocumentModel appFlags componentModel componentMsgIn componentMsgOut output
    -> Sub (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output)
subscriptions virtualProgram =
    .componentModel
        >> virtualProgram.subscriptions
        >> Sub.map MsgForComponent


view :
    (output -> Html componentMsgIn)
    -> VirtualProgram appFlags componentModel componentMsgIn componentMsgOut output
    -> DocumentModel appFlags componentModel componentMsgIn componentMsgOut output
    -> Document (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output)
view toHtml virtualProgram { componentModel, sandboxComponent } =
    let
        output =
            toHtml <| virtualProgram.view (always Nothing) componentModel
    in
    layout output sandboxComponent



---


layout :
    Html componentMsgIn
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> Document (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output)
layout outputHtml sandboxComponent =
    let
        newBody =
            List.append
                meta
                [ Html.div [ HtmlA.class "Layout" ]
                    [ Html.section [ HtmlA.class "Output" ] [ Html.map MsgForComponent outputHtml ]
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
        >> List.sortBy Tuple.first
        >> List.map Tuple.second
        >> Html.div [ HtmlA.class "list-group" ]


viewTestCase :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> ( Int, Html (DocumentMsg appFlags componentModel componentMsgIn componentMsgOut output) )
viewTestCase testCase =
    let
        viewModel =
            case TestCase.toResult testCase of
                Nothing ->
                    { passed = Nothing
                    , itemClass = ""
                    , textColor = ""
                    , testStatusText = ""
                    , errorText = ""
                    , order = 2
                    }

                Just expectation ->
                    case TestRunner.getFailureReason expectation of
                        Nothing ->
                            { passed = Nothing
                            , itemClass = "list-group-item-success"
                            , textColor = "text-success"
                            , testStatusText = "Test Passed"
                            , errorText = ""
                            , order = 3
                            }

                        Just { given, description } ->
                            { passed = Nothing
                            , itemClass = "list-group-item-danger"
                            , textColor = "text-danger"
                            , testStatusText = "Test Failed"
                            , errorText =
                                (given
                                    |> Maybe.map (\g -> g ++ "\n\n")
                                    |> Maybe.withDefault ""
                                )
                                    ++ description
                            , order = 1
                            }
    in
    ( viewModel.order
    , Html.div
        [ HtmlA.class <| "list-group-item list-group-item-action " ++ viewModel.itemClass
        , HtmlE.onClick (MsgForDocument <| RunTestCase testCase)
        ]
        [ Html.div [ HtmlA.class "d-flex w-100 justify-content-between" ]
            [ Html.h5 [ HtmlA.class "mb-1" ]
                [ Html.text <| TestCase.toTitle testCase ]
            , Html.small [ HtmlA.class viewModel.textColor ]
                [ Html.text viewModel.testStatusText
                ]
            ]
        , Html.p [ HtmlA.class "mb-1" ]
            [ Html.text <| TestCase.toDescription testCase ]
        , if viewModel.errorText /= "" then
            Html.pre [ HtmlA.class "mb-1" ] [ viewModel.errorText |> Html.text ]

          else
            Html.text ""
        ]
    )


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
    .Output { padding: 30px; min-height: 140px; height: 50%; overflow: auto; resize: vertical; border-bottom: 1px solid rgba(0,0,0,.125); background-size: 10px 10px; background-image: linear-gradient(to right, #E2F4FB 1px, transparent 1px), linear-gradient(to bottom, #E2F4FB 1px, transparent 1px); box-shadow: inset 0 0 10px 10px rgba(0,0,0,.3); }
    .Info { flex: 1 1 auto; overflow: auto; padding: 30px; }
    """
        |> Html.text
        |> List.singleton
        |> Html.node "style" [ HtmlA.type_ "text/css" ]
