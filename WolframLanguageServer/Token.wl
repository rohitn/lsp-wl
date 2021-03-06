(* ::Package:: *)

(* Wolfram Language Server Documentation *)
(* Author: kenkangxgwe <kenkangxgwe_at_gmail.com>, 
           huxianglong <hxianglong_at_gmail.com>
*)


BeginPackage["WolframLanguageServer`Token`"];
ClearAll[Evaluate[Context[] <> "*"]];


TokenDocumentation::usage = "TokenDocumentation[token_String] returns the documentation for input token in Markdown format.
  The possible options are
  \"Format\" -> \"Text\" | \"Picture\",
  \"Theme\" -> \"Dark\" | \"Light\",
  \"TempDir\" -> $TemporaryDirectory
";

TokenKind::usage = "TokenKind[token_String] returns the symbol kind of input token. See WolframLanguageServer`Specification`CompletionItemKind.";

TokenCompletionList::usage = "TokenCompletionList[token_String] returns a list of predicted completions for the input token.";


Begin["`Private`"];
ClearAll[Evaluate[Context[] <> "*"]];
Needs["WolframLanguageServer`Specification`"];


(* ::Section:: *)
(*Documentation*)


Options[TokenDocumentation] = {
    "Format" -> "Text",
    "Theme" -> "Dark",
    "TempDir" -> $TemporaryDirectory
};

TokenDocumentation[token_String, o: OptionsPattern[]] := Module[
    {
        format, theme, tempdir
    },
    
    {format, theme, tempdir} = OptionValue[TokenDocumentation, {o}, {"Format", "Theme", "TempDir"}];
    If[Head[ToExpression[token<>"::usage"]] === MessageName, Return[""]];
    StringJoin[{
        GenHeader[token],
        "\t",
        GetUri[token],
	    If[format === "Text", 
	        GenMdText[token],
	        GenSvgImg[token, 450, "Theme" -> theme, "TempDir" -> tempdir]
	    ]
	}]
];


GenHeader[token_String] := "**" <> token <> "**";


(* TODO: check valid url *)
GetUri[token_String] := ("[" <> "*Website Reference*" (*<> "*" <> token <> "*"*) <> "](https://reference.wolfram.com/language/ref/" <> token <> ".html)" <> "\n\n");


ToMarkdown[input_String] := Module[
	{
	
	},
	StringReplace[input, {
	    Shortest["\!\(\*"~~box__~~"\)"] :> ToString["\!\(\*" <> ToString[
	        ToExpression[box, StandardForm] //.{
	            (*RowBox \[Rule] StringJoin,*)
	            StyleBox[x_, "TI"] :> ("*" <> ToMarkdown[x] <> "*"),
	            StyleBox[x_, "TR"] :> ToMarkdown[x], 
	            StyleBox[x_, ShowStringCharacters->True] :> ToMarkdown[x],
	            SubscriptBox[x_, y_] :> (ToMarkdown[x] <> "\\_"<>ToMarkdown[y]),
	            SuperscriptBox["\[Null]", y_] :> ("-" <> ToMarkdown[y]),
	            SuperscriptBox[x_, y_] :> (ToMarkdown[x] <> "^" <> ToMarkdown[y]),
	            SubsuperscriptBox[x_, y_, z_] :> (ToMarkdown[x] <> "\\_" <> ToMarkdown[y] <> "^" <> ToMarkdown[z]),
	            UnderscriptBox[x_, y_] :> "Underscript[" <> ToMarkdown[x] <> ", " <> ToMarkdown[y] <> "]",
	            OverscriptBox[x_, y_] :> "Overscript[" <> ToMarkdown[x] <> ", " <> ToMarkdown[y] <> "]",
	            UnderoverscriptBox[x_,y_,z_] :> "Underoverscript[" <> ToMarkdown[x] <> ", " <> ToMarkdown[y] <> ", " <> ToMarkdown[z] <> "]",
	            FractionBox[x_, y_] :> (ToMarkdown[x] <> "/" <> ToMarkdown[y]),
	            SqrtBox[x_] :> ("Sqrt[" <> ToMarkdown[x] <> "]"),
	            RadicalBox[x_, y_] :> (ToMarkdown[x] <> "^{1/" <> ToMarkdown[y] <> "}"),
	            "\[Rule]" -> "\[RightArrow]",
	            (*"\[Ellipsis]" \[Rule] "...",*)
	            (*"\[DoubleRightArrow]" \[Rule] " => ",*)
	            Nothing
	        }, InputForm] <> "\)"
	    ]
	}]
];

GenMdText[token_String] := Module[
	{
	    ForceStringJoin, usageString
	},
	
	ForceStringJoin = StringJoin @* Map[ReplaceAll[x:Except[_String] :> ToString[x]]];
	usageString = ToMarkdown[ToExpression[token <> "::usage"]] //.{StringJoin[x_List] :> ForceStringJoin[x], StringJoin[x__] :> ForceStringJoin[{x}]};
	StringReplace[usageString, {
        StartOfLine -> "___\n",
	    "\n"->"\n\n"
	}] <> "\n\n"
];


Options[GenSvgImg] := {
	"Theme" -> "dark",
	"TempDir" -> $TemporaryDirectory
};

GenSvgImg[token_String, width_Integer, o:OptionsPattern[]] := Module[
	{
		tempImgPath, background, theme, tempDir
	},
	
	{theme, tempImgPath} = OptionValue[GenSvgImg, {o}, {"Theme", "TempDir"}];
	background = If[theme === "light", Black, White];
	tempImgPath = FileNameJoin[{tempDir, CreateUUID[] <> ".svg"}];
	(* Export[tempImgPath, Style[#, background]& @* (#::usage&) @ Symbol[token]]; *)
	Export[tempImgPath, 
		Style[
			Pane[StringReplace[#, StartOfLine -> "\[FilledSmallCircle] "], .85*width, Alignment -> Left], FontSize -> 13, background
		]& @ ToExpression[token <> "::usage"]
	];
	(* "![" <> "test" <> "](" <> tempImgPath <> ")" <> "\n" <> "```" <> StringRepeat[StringJoin[CharacterRange["a", "z"]], 4] <> "```" *)
	"![" <> "test" <> "](" <> tempImgPath <> ")" <> "\n\n" <> "```typescript" <> StringRepeat[StringRepeat["\t", 50] <> "\n", 20] <> "```" <> "\n\n"
	(* "![" <> ToString[(#::usage&) @ Symbol[token]] <> "](" <> tempImgPath <> ")" *)
]; 


(* ::Section:: *)
(*Kind*)


TokenKind[token_String] := Module[
    {
    },
    (*If[Context[token] === "Global`",
        
    If[OwnValues[Symbol[token]] === {},
        CompletionItemKind["Function"],
        CompletionItemKind["Variable"]
    ]*)
    
    If[StringTake[token, 1] === "$",
        CompletionItemKind["Variable"],
        CompletionItemKind["Function"]
    ]
];


(* ::Section:: *)
(*GetCommonToken*)


TokenCompletionList[token_String] := Module[
    {
        allNames
    },
   
    allNames = Names["System`" <> token <> "*"]
];


End[];


EndPackage[];
