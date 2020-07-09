module Framework.Internal.TestCases.TestCase exposing
    ( TestCase
    , addActions
    , make
    , reInit
    , setActions
    , setResult
    , toActions
    , toDescription
    , toResult
    , toTest
    , toTitle
    )

import Expect exposing (Expectation)


type TestCase appFlags componentModel componentMsgIn componentMsgOut output
    = TestCase
        { title : String
        , description : String
        , reInitWithFlags : Maybe appFlags
        , actions : List componentMsgIn
        , test : (componentModel -> output) -> componentModel -> ( componentModel, List componentMsgOut ) -> Expectation
        , mockMsgOut : componentMsgOut -> Maybe componentMsgIn
        , result : Maybe Expectation
        }


toTitle : TestCase appFlags componentModel componentMsgIn componentMsgOut output -> String
toTitle (TestCase { title }) =
    title


toDescription : TestCase appFlags componentModel componentMsgIn componentMsgOut output -> String
toDescription (TestCase { description }) =
    description


toActions : TestCase appFlags componentModel componentMsgIn componentMsgOut output -> List componentMsgIn
toActions (TestCase { actions }) =
    actions


toTest :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> ((componentModel -> output) -> componentModel -> ( componentModel, List componentMsgOut ) -> Expectation)
toTest (TestCase { test }) =
    test


toResult :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> Maybe Expectation
toResult (TestCase { result }) =
    result


make :
    { title : String
    , description : String
    , test : (componentModel -> output) -> componentModel -> ( componentModel, List componentMsgOut ) -> Expectation
    }
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
make { title, description, test } =
    TestCase
        { title = title
        , description = description
        , reInitWithFlags = Nothing
        , actions = []
        , test = test
        , result = Nothing
        , mockMsgOut = \_ -> Nothing
        }


reInit :
    appFlags
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
reInit appFlags (TestCase testCase) =
    TestCase { testCase | reInitWithFlags = Just appFlags }


setActions :
    List componentMsgIn
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
setActions actions (TestCase testCase) =
    TestCase { testCase | actions = actions }


addActions :
    List componentMsgIn
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
addActions actions (TestCase testCase) =
    TestCase { testCase | actions = List.append testCase.actions actions }


setResult :
    Expectation
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
setResult result (TestCase testCase) =
    TestCase { testCase | result = Just result }
