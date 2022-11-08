module TokenizeTest exposing (suite)

import Elm.Compiler.Error exposing (Error(..), TokenizeError(..))
import Elm.Data.Token exposing (Token(..))
import Expect
import Stage.Tokenize
import Test exposing (Test)


suite : Test
suite =
    let
        runTest : ( String, String, Result TokenizeError (List Token) ) -> Test
        runTest ( description, input, output ) =
            Test.test description <|
                \() ->
                    input
                        |> Stage.Tokenize.tokenize
                        |> Expect.equal
                            (output
                                |> Result.mapError TokenizeError
                            )
    in
    Test.describe "Stage.Tokenize.tokenize"
        (List.map runTest
            -- TODO error cases, correct "startColumn" etc.
            [ ( "lowerName", "helloWorld", Ok [ LowerName "helloWorld" ] )
            , ( "upperName", "HelloWorld", Ok [ UpperName "HelloWorld" ] )
            , ( "int positive", "123", Ok [ Int 123 ] )
            , ( "int negative", "-123", Ok [ Int -123 ] )
            , ( "hex int positive", "0x123", Ok [ Int 291 ] )
            , ( "hex int negative", "-0x123", Ok [ Int -291 ] )
            , ( "float positive", "123.45", Ok [ Float 123.45 ] )
            , ( "float negative", "-123.45", Ok [ Float -123.45 ] )
            , ( "float positive scientific-positive", "1.2e3", Ok [ Float 1200 ] )
            , ( "float negative scientific-positive", "-1.2e3", Ok [ Float -1200 ] )
            , ( "float positive scientific-negative", "1.2e-3", Ok [ Float 0.0012 ] )
            , ( "float negative scientific-negative", "-1.2e-3", Ok [ Float -0.0012 ] )
            , ( "hex int edge case", "0x5e3", Ok [ Int 1507 ] )
            , ( "char", "'a'", Ok [ Char 'a' ] )
            , ( "escaped n in a char", "'\\n'", Ok [ Char '\n' ] )
            , ( "escaped r in a char", "'\\r'", Ok [ Char '\u{000D}' ] )
            , ( "escaped t in a char", "'\\t'", Ok [ Char '\t' ] )
            , ( "escaped \" in a char", "'\\\"'", Ok [ Char '"' ] )
            , ( "escaped ' in a char", "'\\''", Ok [ Char '\'' ] )
            , ( "escaped \\ in a char", "'\\\\'", Ok [ Char '\\' ] )
            , ( "escaped uppercase unicode in a char", "'\\u{000D}'", Ok [ Char '\u{000D}' ] )
            , ( "escaped lowercase unicode in a char", "'\\u{000d}'", Ok [ Char '\u{000D}' ] )
            , ( "multiple things in a char"
              , "'ab'"
              , Err <|
                    CharTooLong
                        { charContents = "ab"
                        , startLine = 1
                        , startColumn = 2
                        }
              )
            , ( "string", "\"a\"", Ok [ String "a" ] )
            , ( "multiline string", "\"\"\"a\n  b\"\"\"", Ok [ String "a\n  b" ] )
            , ( "operator +", "+", Ok [ Operator "+" ] )
            , ( "operator ==", "==", Ok [ Operator "==" ] )
            , ( "operator == with numbers", "1 == 2", Ok [ Int 1, Operator "==", Int 2 ] )

            -- keywords
            , ( "port", "port", Ok [ Port ] )
            , ( "effect", "effect", Ok [ Effect ] )
            , ( "module", "module", Ok [ Module ] )
            , ( "exposing", "exposing", Ok [ Exposing ] )
            , ( "type", "type", Ok [ Type ] )
            , ( "alias", "alias", Ok [ Alias ] )
            , ( "import", "import", Ok [ Import ] )
            , ( "if", "if", Ok [ If ] )
            , ( "then", "then", Ok [ Then ] )
            , ( "else", "else", Ok [ Else ] )
            , ( "let", "let", Ok [ Let ] )
            , ( "in", "in", Ok [ In ] )
            , ( "case", "case", Ok [ Case ] )
            , ( "of", "of", Ok [ Of ] )

            -- symbols
            , ( "dot", ".", Ok [ Dot ] )
            , ( "dot in a module name", "My.Module", Ok [ UpperName "My", Dot, UpperName "Module" ] )
            , ( "all", "(..)", Ok [ All ] )
            , ( "all next to module..exposing", "module Main exposing (..)", Ok [ Module, UpperName "Main", Exposing, All ] )
            , ( "all next to import..exposing", "import Main exposing (..)", Ok [ Import, UpperName "Main", Exposing, All ] )
            , ( "all next to import type..exposing", "import Main exposing (Foo(..))", Ok [ Import, UpperName "Main", Exposing, LeftParen, UpperName "Foo", All, RightParen ] )
            , ( "comma", ",", Ok [ Comma ] )
            , ( "comma in tuple", "(a,b)", Ok [ LeftParen, LowerName "a", Comma, LowerName "b", RightParen ] )
            , ( "as", "as", Ok [ As ] )
            , ( "equals", "=", Ok [ Equals ] )
            , ( "equals in declaration", "foo = 1", Ok [ LowerName "foo", Equals, Int 1 ] )
            , ( "minus", "-", Ok [ Minus ] )
            , ( "minus with two numbers", "1 - 2", Ok [ Int 1, Minus, Int 2 ] )
            , ( "backslash", "\\", Ok [ Backslash ] )
            , ( "backslash in a lambda", "\\x -> x", Ok [ Backslash, LowerName "x", RightArrow, LowerName "x" ] )
            , ( "left paren", "(", Ok [ LeftParen ] )
            , ( "right paren", ")", Ok [ RightParen ] )
            , ( "left and right paren in an unit", "()", Ok [ LeftParen, RightParen ] )
            , ( "left curly bracket", "{", Ok [ LeftCurlyBracket ] )
            , ( "right curly bracket", "}", Ok [ RightCurlyBracket ] )
            , ( "curly brackets in empty record", "{}", Ok [ LeftCurlyBracket, RightCurlyBracket ] )
            , ( "colon", ":", Ok [ Colon ] )
            , ( "colon in type", "x : Int", Ok [ LowerName "x", Colon, UpperName "Int" ] )
            , ( "pipe", "|", Ok [ Pipe ] )
            , ( "pipe in custom type", "type X = A | B", Ok [ Type, UpperName "X", Equals, UpperName "A", Pipe, UpperName "B" ] )
            , ( "underscore", "_", Ok [ Underscore ] )
            , ( "underscore in lambda", "\\_ -> 1", Ok [ Backslash, Underscore, RightArrow, Int 1 ] )
            ]
        )