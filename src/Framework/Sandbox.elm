module Framework.Sandbox exposing
    ( SandboxComponent
    , addTestCase
    , fromComponent
    , toTest
    , updateTestCase
    )

import Framework.Actor exposing (Component)
import Framework.Internal.SandboxComponent as SandboxComponent
import Framework.Internal.TestCases.TestCase as TestCase exposing (TestCase)
import Framework.Internal.VirtualProgram as VirtualProgram
import Framework.Message exposing (FrameworkMessage)
import Test exposing (Test)


type alias SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output =
    SandboxComponent.SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output


fromComponent :
    appFlags
    -> Component appFlags componentModel componentMsgIn componentMsgOut output (FrameworkMessage appFlags () () componentModel componentMsgIn)
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
fromComponent =
    SandboxComponent.fromComponent


addTestCase :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
addTestCase =
    SandboxComponent.addTestCase


updateTestCase :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
updateTestCase =
    SandboxComponent.updateTestCase


toTest :
    String
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> Test
toTest description sandboxComponent =
    let
        virtualProgram =
            VirtualProgram.toVirtualProgram sandboxComponent
    in
    SandboxComponent.toTestCases sandboxComponent
        |> List.map
            (\testCase ->
                Test.test (TestCase.toTitle testCase) <|
                    \_ ->
                        VirtualProgram.testTestCase virtualProgram testCase
            )
        |> Test.describe description
