module Framework.Internal.VirtualProgram exposing
    ( VirtualProgram
    , runTestCase
    , testTestCase
    , toVirtualProgram
    )

import Expect exposing (Expectation)
import Framework.Actor as Actor exposing (Actor)
import Framework.Browser as Browser exposing (FrameworkModel)
import Framework.Internal.SandboxComponent as SandboxComponent exposing (SandboxComponent)
import Framework.Internal.TestCases.TestCase as TestCase exposing (TestCase)
import Framework.Message as Message exposing (FrameworkMessage)


type alias VirtualProgram appFlags componentModel componentMsgIn output =
    { init : ( FrameworkModel () componentModel, Cmd (FrameworkMessage appFlags () () componentModel componentMsgIn) )
    , update :
        FrameworkMessage appFlags () () componentModel componentMsgIn
        -> FrameworkModel () componentModel
        -> ( FrameworkModel () componentModel, Cmd (FrameworkMessage appFlags () () componentModel componentMsgIn) )
    , subscriptions : FrameworkModel () componentModel -> Sub (FrameworkMessage appFlags () () componentModel componentMsgIn)
    , actor : Actor appFlags componentModel componentModel output (FrameworkMessage appFlags () () componentModel componentMsgIn)
    }


toVirtualProgram :
    SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> VirtualProgram appFlags componentModel componentMsgIn output
toVirtualProgram sandboxComponent =
    let
        actor =
            SandboxComponent.toComponent sandboxComponent
                |> Actor.fromComponent
                    { toAppModel = identity
                    , toAppMsg = identity
                    , fromAppMsg = Just << identity
                    , onMsgOut = \_ -> Message.noOperation
                    }

        programRecord =
            Browser.toProgramRecord
                { factory = \_ -> actor.init
                , apply = actor.apply
                }

        initMsg =
            Message.spawn
                (SandboxComponent.toInitFlags sandboxComponent)
                ()
                Message.addToView
    in
    { init = programRecord.init initMsg
    , update = programRecord.update
    , subscriptions = programRecord.subscriptions
    , actor = actor
    }


runTestCase :
    VirtualProgram appFlags componentModel componentMsgIn output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> ( FrameworkModel () componentModel, Maybe componentModel )
runTestCase virtualProgram testCase =
    let
        -- initMsg =
        --     Message.spawn
        --         (SandboxComponent.toInitFlags sandboxComponent)
        --         ()
        --         Message.addToView
        initialState =
            Tuple.first virtualProgram.init

        pid =
            initialState.lastPid

        endState =
            TestCase.toActions testCase
                |> List.foldl
                    (\msg_ model_ ->
                        virtualProgram.update (Message.sendToPid pid msg_) model_
                            |> Tuple.first
                    )
                    initialState
    in
    ( endState, Browser.getInstance pid endState )


testTestCase :
    VirtualProgram appFlags componentModel componentMsgIn output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> Expectation
testTestCase virtualProgram testCase =
    let
        initialState =
            Tuple.first virtualProgram.init

        pid =
            initialState.lastPid

        maybeInitialComponentModel =
            Browser.getInstance pid initialState

        maybeResultComponentModel =
            runTestCase virtualProgram testCase |> Tuple.second
    in
    case ( maybeInitialComponentModel, maybeResultComponentModel ) of
        ( Just a, Just b ) ->
            TestCase.toTest testCase
                (virtualProgram.actor.apply >> (\{ view } -> view pid (always Nothing)))
                a
                ( b, [] )

        _ ->
            Expect.fail "System Error"
