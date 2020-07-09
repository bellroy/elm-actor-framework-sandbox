module Framework.Sandbox.TestCase exposing
    ( TestCase
    , addActions
    , make
    , reInit
    , setActions
    , toDescription
    , toTitle
    )

import Expect exposing (Expectation)
import Framework.Internal.TestCases.TestCase as Internal


type alias TestCase appFlags componentModel componentMsgIn componentMsgOut output =
    Internal.TestCase appFlags componentModel componentMsgIn componentMsgOut output


make :
    { title : String
    , description : String
    , test : (componentModel -> output) -> componentModel -> ( componentModel, List componentMsgOut ) -> Expectation
    }
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
make =
    Internal.make


reInit :
    appFlags
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
reInit =
    Internal.reInit


setActions :
    List componentMsgIn
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
setActions =
    Internal.setActions


addActions :
    List componentMsgIn
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
addActions =
    Internal.addActions


toTitle : TestCase appFlags componentModel componentMsgIn componentMsgOut output -> String
toTitle =
    Internal.toTitle


toDescription : TestCase appFlags componentModel componentMsgIn componentMsgOut output -> String
toDescription =
    Internal.toDescription
