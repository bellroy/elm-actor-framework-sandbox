module Framework.Sandbox.Browser exposing
    ( document
    , Program
    )

{-|

@docs document

@docs Program

-}

import Framework.Sandbox.Internal.Browser as Internal
import Framework.Sandbox.Internal.SandboxComponent exposing (SandboxComponent)
import Html exposing (Html)


{-| The signature of the program that gets created using `document`
-}
type alias Program appFlags componentModel componentMsgIn componentMsgOut output =
    Internal.Program appFlags componentModel componentMsgIn componentMsgOut output


{-| Turn your component into an Elm Program (!)

**Tip** On your components module create an exposed `main` function on which you invode this function.
You can then `elm reactor` to directly navigate to your components file and get a preview of your components output + test results

-}
document :
    (output -> Html componentMsgIn)
    -> SandboxComponent appFlags componentModel componentMsgIn componentMsgOut output
    -> Program appFlags componentModel componentMsgIn componentMsgOut output
document =
    Internal.document
