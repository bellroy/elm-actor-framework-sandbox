module Framework.Sandbox.TestCase exposing
    ( TestCase, make
    , addActions, setActions
    , onInit
    , mockMsgOut
    )

{-|

@docs TestCase, make

@docs addActions, setActions

@docs onInit

@docs mockMsgOut

-}

import Browser exposing (UrlRequest(..))
import Expect exposing (Expectation)
import Framework.Sandbox.Internal.TestCases.TestCase as Internal


{-| -}
type alias TestCase appFlags componentModel componentMsgIn componentMsgOut output =
    Internal.TestCase appFlags componentModel componentMsgIn componentMsgOut output


{-| Create a new TestCase
-}
make :
    { title : String
    , description : String
    , test : (componentModel -> output) -> componentModel -> componentModel -> Expectation
    }
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
make =
    Internal.make


{-| Supply an alternative intial value
(alternative to your SandboxComponent)
-}
onInit :
    appFlags
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
onInit =
    Internal.onInit


{-| Replace all current actions with a new list of actions
-}
setActions :
    List componentMsgIn
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
setActions =
    Internal.setActions


{-| Append a list of actions to your current actions in place.
-}
addActions :
    List componentMsgIn
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
addActions =
    Internal.addActions


{-| Mock a response message whenever a msgOut gets called
-}
mockMsgOut :
    (componentMsgOut -> Maybe componentMsgIn)
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
mockMsgOut =
    Internal.mockMsgOut
