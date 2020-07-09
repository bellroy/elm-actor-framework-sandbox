module Example exposing (suite)

import Expect exposing (Expectation)
import Test exposing (Test, test)
import Sandbox.Components.Timer.Main as Main
import Framework.Sandbox as Sandbox


suite : Test
suite =
    Sandbox.toTest "Timer Component" Main.sandboxed 