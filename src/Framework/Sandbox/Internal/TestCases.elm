module Framework.Sandbox.Internal.TestCases exposing
    ( TestCases
    , empty
    , insert
    , remove
    , toList
    , update
    )

import Dict exposing (Dict)
import Framework.Sandbox.Internal.TestCases.TestCase as TestCase exposing (TestCase)


type TestCases appFlags componentModel componentMsgIn componentMsgOut output
    = TestCases (Dict String (TestCase appFlags componentModel componentMsgIn componentMsgOut output))


empty : TestCases appFlags componentModel componentMsgIn componentMsgOut output
empty =
    fromDict Dict.empty


insert :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCases appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCases appFlags componentModel componentMsgIn componentMsgOut output
insert testCase =
    toDict
        >> Dict.insert (TestCase.toTitle testCase) testCase
        >> fromDict


update :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCases appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCases appFlags componentModel componentMsgIn componentMsgOut output
update =
    insert


remove :
    TestCase appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCases appFlags componentModel componentMsgIn componentMsgOut output
    -> TestCases appFlags componentModel componentMsgIn componentMsgOut output
remove testCase =
    toDict >> Dict.remove (TestCase.toTitle testCase) >> fromDict


toList :
    TestCases appFlags componentModel componentMsgIn componentMsgOut output
    -> List (TestCase appFlags componentModel componentMsgIn componentMsgOut output)
toList =
    toDict >> Dict.toList >> List.map Tuple.second


toDict :
    TestCases appFlags componentModel componentMsgIn componentMsgOut output
    -> Dict String (TestCase appFlags componentModel componentMsgIn componentMsgOut output)
toDict (TestCases dict) =
    dict


fromDict :
    Dict String (TestCase appFlags componentModel componentMsgIn componentMsgOut output)
    -> TestCases appFlags componentModel componentMsgIn componentMsgOut output
fromDict =
    TestCases
