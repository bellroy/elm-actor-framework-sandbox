module Framework.Sandbox exposing
    ( SandboxComponent, fromComponent
    , addTestCase, updateTestCase, toTest
    )

{-|

@docs SandboxComponent, fromComponent


# Tests

@docs addTestCase, updateTestCase, toTest

-}

import Framework.Actor exposing (Component)
import Framework.Sandbox.Internal.SandboxComponent as SandboxComponent
import Framework.Sandbox.Internal.TestCases.TestCase as TestCase exposing (TestCase)
import Framework.Sandbox.Internal.VirtualProgram as VirtualProgram
import Test exposing (Test)


{-| -}
type alias SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output =
    SandboxComponent.SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output


{-| Turn your Framework.Actor.Component into a SandboxComponent.

You'll have to supply it with a default (mocked) `appFlags` value so that we can
render an initial output (See `Framework.Sandbox.Browser` for more info.)

    fromComponent "Some Flags" component

-}
fromComponent :
    appFlags
    -> Component appFlags componentModel componentMsgIn componentMsgOut output componentMsgIn
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
fromComponent =
    SandboxComponent.fromComponent


{-| Add A TestCase to your SandboxComponent

The title of a TestCase has to be unique for your Sandbox.

    fromComponent () component
        |> addTestCase
            (TestCase.make
                { title = "Increment"
                , description = "Increment the counters value by one."
                , test = \_ a b -> Expect (b - a) 1
                }
                |> TestCase.setActions [ Increment ]
            )

-}
addTestCase :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
addTestCase =
    SandboxComponent.addTestCase


{-| Updates a TestCase based on its title (This is an alias of addTestCase (!))
-}
updateTestCase :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
updateTestCase =
    SandboxComponent.updateTestCase


{-| Give your tests a description and turn them into Elm tests!

    fromComponent () component
        |> addTestCase
            (TestCase.make
                { title = "Increment"
                , description = "Increment the counters value by one."
                , test = \_ a b -> Expect (b - a) 1
                }
                |> TestCase.setActions [ Increment ]
            )
        |> toTest "My Counter Component"

-}
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
                (\_ -> VirtualProgram.testTestCase virtualProgram testCase)
                    |> Test.test (TestCase.toTitle testCase)
            )
        |> Test.describe description
