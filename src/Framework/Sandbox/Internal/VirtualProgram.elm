module Framework.Sandbox.Internal.VirtualProgram exposing
    ( VirtualProgram
    , runTestCase
    , testTestCase
    , toVirtualProgram
    )

import Expect exposing (Expectation)
import Framework.Actor as Actor exposing (Pid)
import Framework.Sandbox.Internal.SandboxComponent as SandboxComponent exposing (SandboxComponent)
import Framework.Sandbox.Internal.TestCases.TestCase as TestCase exposing (TestCase)


type alias VirtualProgram appFlags componentModel componentMsgIn componentMsgOut output =
    { init : (Int -> componentMsgOut -> List componentMsgIn) -> Maybe appFlags -> ( componentModel, Cmd componentMsgIn )
    , update : (Int -> componentMsgOut -> List componentMsgIn) -> componentMsgIn -> componentModel -> ( componentModel, Cmd componentMsgIn )
    , subscriptions : componentModel -> Sub componentMsgIn
    , view : (Pid -> Maybe output) -> componentModel -> output
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
            indexedFoldl
                (\index msgOut ( model_, cmd_ ) ->
                    List.foldl
                        (\msgIn ( model__, cmd__ ) ->
                            update onMsgOut msgIn model__
                                |> Tuple.mapSecond (\cmd___ -> Cmd.batch [ cmd__, cmd___ ])
                        )
                        ( model_, cmd_ )
                        (onMsgOut index msgOut)
                )
                ( model, cmd )
                listMsgOut

        subscriptions =
            component.subscriptions

        view renderPid model =
            component.view identity model renderPid
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

        renderPid =
            TestCase.toRenderPid testCase
    in
    TestCase.toTest
        testCase
        (virtualProgram.view renderPid)
        initialState
        resultState


indexedFoldl : (Int -> a -> b -> b) -> b -> List a -> b
indexedFoldl f b =
    List.foldl
        (\a ( i, b_ ) -> ( i + 1, f i a b_ ))
        ( 0, b )
        >> Tuple.second
