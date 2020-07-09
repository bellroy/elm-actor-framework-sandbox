module Framework.Internal.SandboxComponent exposing
    ( SandboxComponent
    , addTestCase
    , fromComponent
    , toComponent
    , toInitFlags
    , toTestCases
    , updateTestCase
    )

import Framework.Actor exposing (Component)
import Framework.Internal.TestCases as TestCases exposing (TestCases)
import Framework.Internal.TestCases.TestCase exposing (TestCase)
import Framework.Message exposing (FrameworkMessage)


type SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    = SandboxComponent
        { component :
            Component appFlags componentModel componentMsgIn componentMsgOut output (FrameworkMessage appFlags () () componentModel componentMsgIn)
        , init : appFlags
        , testCases : TestCases appFlags componentModel componentMsgIn componentMsgOut output
        }


fromComponent :
    appFlags
    -> Component appFlags componentModel componentMsgIn componentMsgOut output (FrameworkMessage appFlags () () componentModel componentMsgIn)
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
fromComponent appFlags component =
    SandboxComponent
        { component = component
        , init = appFlags
        , testCases = TestCases.empty
        }


addTestCase :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
addTestCase testCase (SandboxComponent sandboxComponent) =
    SandboxComponent
        { sandboxComponent
            | testCases = TestCases.insert testCase sandboxComponent.testCases
        }


updateTestCase :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
updateTestCase testCase (SandboxComponent sandboxComponent) =
    SandboxComponent
        { sandboxComponent
            | testCases = TestCases.update testCase sandboxComponent.testCases
        }


toComponent :
    SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> Component appFlags componentModel componentMsgIn componentMsgOut output (FrameworkMessage appFlags () () componentModel componentMsgIn)
toComponent (SandboxComponent { component }) =
    component


toInitFlags : SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output -> appFlags
toInitFlags (SandboxComponent { init }) =
    init


toTestCases :
    SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> List (TestCase appFlags componentModel componentMsgIn componentMsgOut output)
toTestCases (SandboxComponent { testCases }) =
    TestCases.toList testCases
