module Framework.Sandbox.Internal.TestCases.TestCase exposing
    ( TestCase
    , addActions
    , make
    , mockMsgOut
    , mockRenderPid
    , onInit
    , setActions
    , setResult
    , toActions
    , toAppFlags
    , toDescription
    , toOnMsgOut
    , toRenderPid
    , toResult
    , toTest
    , toTitle
    )

import Expect exposing (Expectation)
import Framework.Actor exposing (Pid)


type TestCase appFlags componentModel componentMsgIn componentMsgOut output
    = TestCase
        { title : String
        , description : String
        , appFlags : Maybe appFlags
        , actions : List componentMsgIn
        , test : (componentModel -> output) -> componentModel -> componentModel -> Expectation
        , onMsgOut : componentMsgOut -> List componentMsgIn
        , renderPid : Pid -> Maybe output
        , result : Maybe Expectation
        }


toTitle :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> String
toTitle (TestCase { title }) =
    title


toDescription :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> String
toDescription (TestCase { description }) =
    description


toActions :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> List componentMsgIn
toActions (TestCase { actions }) =
    actions


toTest :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> ((componentModel -> output) -> componentModel -> componentModel -> Expectation)
toTest (TestCase { test }) =
    test


toResult :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> Maybe Expectation
toResult (TestCase { result }) =
    result


toAppFlags :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> Maybe appFlags
toAppFlags (TestCase { appFlags }) =
    appFlags


make :
    { title : String
    , description : String
    , test : (componentModel -> output) -> componentModel -> componentModel -> Expectation
    }
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
make { title, description, test } =
    TestCase
        { title = title
        , description = description
        , appFlags = Nothing
        , actions = []
        , test = test
        , result = Nothing
        , renderPid = always Nothing
        , onMsgOut = \_ -> []
        }


onInit :
    appFlags
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
onInit appFlags (TestCase testCase) =
    TestCase { testCase | appFlags = Just appFlags }


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


mockMsgOut :
    (componentMsgOut -> List componentMsgIn)
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
mockMsgOut onMsgOut (TestCase testCase) =
    TestCase { testCase | onMsgOut = onMsgOut }


toOnMsgOut :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> (componentMsgOut -> List componentMsgIn)
toOnMsgOut (TestCase { onMsgOut }) =
    onMsgOut


mockRenderPid :
    (Pid -> Maybe output)
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCase appFlags componentModel componentMsgIn componentMsgOut output
mockRenderPid renderPid (TestCase testCase) =
    TestCase { testCase | renderPid = renderPid }


toRenderPid :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> (Pid -> Maybe output)
toRenderPid (TestCase { renderPid }) =
    renderPid
