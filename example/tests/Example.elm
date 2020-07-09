module Example exposing (suite)

import Framework.Sandbox as Sandbox
import Sandbox.Components.Timer.Main as Main
import Test exposing (Test)


suite : Test
suite =
    Sandbox.toTest "Timer Component" Main.sandboxed
