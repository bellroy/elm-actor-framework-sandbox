module Framework.Sandbox.Internal.VirtualProgram exposing
    ( VirtualProgram
    , runTestCase
    , testTestCase
    , toVirtualProgram
    )

import Expect exposing (Expectation)
import Framework.Actor as Actor
import Framework.Sandbox.Internal.SandboxComponent as SandboxComponent exposing (SandboxComponent)
import Framework.Sandbox.Internal.TestCases.TestCase as TestCase exposing (TestCase)


type alias VirtualProgram appFlags componentModel componentMsgIn componentMsgOut output =
    { init : (componentMsgOut -> Maybe componentMsgIn) -> Maybe appFlags -> ( componentModel, Cmd componentMsgIn )
    , update : (componentMsgOut -> Maybe componentMsgIn) -> componentMsgIn -> componentModel -> ( componentModel, Cmd componentMsgIn )
    , subscriptions : componentModel -> Sub componentMsgIn
    , view : componentModel -> output
    }


toVirtualProgram :
    SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> VirtualProgram appFlags componentModel componentMsgIn componentMsgOut output
toVirtualProgram sandboxComponent =
    let
        component =
            SandboxComponent.toComponent sandboxComponent

        init onMsgOut maybeAppFlags =
            let
                appFlags =
                    Maybe.withDefault
                        (SandboxComponent.toInitFlags
                            sandboxComponent
                        )
                        maybeAppFlags
            in
            component.init ( Actor.pidSystem, appFlags )
                |> afterUpdate onMsgOut

        update onMsgOut msg model =
            component.update msg model
                |> afterUpdate onMsgOut

        afterUpdate onMsgOut ( model, listMsgOut, cmd ) =
            List.foldl
                (\msgOut ( model_, cmd_ ) ->
                    case onMsgOut msgOut of
                        Just msgIn ->
                            update onMsgOut msgIn model_
                                |> Tuple.mapSecond
                                    (\cmd__ ->
                                        Cmd.batch [ cmd_, cmd__ ]
                                    )

                        Nothing ->
                            ( model_, cmd_ )
                )
                ( model, cmd )
                listMsgOut

        subscriptions =
            component.subscriptions

        view model =
            component.view identity model (always Nothing)
    in
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }


runTestCase :
    VirtualProgram appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> ( componentModel, componentModel )
runTestCase virtualProgram testCase =
    let
        onMsgOut =
            TestCase.toOnMsgOut testCase

        initialState =
            virtualProgram.init onMsgOut (TestCase.toAppFlags testCase)
                |> Tuple.first

        resultState =
            TestCase.toActions testCase
                |> List.foldl
                    (\msg_ model_ ->
                        virtualProgram.update onMsgOut msg_ model_
                            |> Tuple.first
                    )
                    initialState
    in
    ( initialState, resultState )


testTestCase :
    VirtualProgram appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> Expectation
testTestCase virtualProgram testCase =
    let
        ( initialState, resultState ) =
            runTestCase virtualProgram testCase
    in
    TestCase.toTest
        testCase
        virtualProgram.view
        initialState
        resultState
