# Vim Syntax HL

Required for cool markdown presentations

## [Regex Recap][R]

[R]: https://learnvimscriptthehardway.stevelosh.com/chapters/31.html

4 modes - Alwasy use `\v` mode. That's like python's.

In a python file say: `:match Error /\vclas./` -> 🥰



## [Basics][B]


[B]: https://learnvimscriptthehardway.stevelosh.com/chapters/45.html

Easy setup:


Write the Vim syntax file.  Or download one from the internet.  Then write it in your
syntax directory.  For example, for the "mine" syntax:  :w ~/.config/nvim/syntax/mine.vim

Now you can start using your syntax file manually:  :set syntax=mine
You don't have to exit Vim to use this.


### Easy Peasy: keywords

colorize stuff like `run` `def` `class`
```python
syntax keyword mylangFunction run   #   -> any string 'run' within buffers with matching filetypes is now a mylangFunction
highlight link mylangFunction Function # -> and will by colorized to whatever rose-pine author defined for *common* keyword Function
```
We could go also direct and JUST define 'run' to be recognized as Function:

    syntax keyword Function run

#### Common Groups:

	*Comment	any comment

	*Constant	any constant
	 String		a string constant: "this is a string"
	 Character	a character constant: 'c', '\n'
	 Number		a number constant: 234, 0xff
	 Boolean	a boolean constant: TRUE, false
	 Float		a floating point constant: 2.3e10

	*Identifier	any variable name
	 Function	function name (also: methods for classes)

	*Statement	any statement
	 Conditional	if, then, else, endif, switch, etc.
	 Repeat		for, do, while, etc.
	 Label		case, default, etc.
	 Operator	"sizeof", "+", "*", etc.
	 Keyword	any other keyword
	 Exception	try, catch, throw

	*PreProc	generic Preprocessor
	 Include	preprocessor #include
	 Define		preprocessor #define
	 Macro		same as Define
	 PreCondit	preprocessor #if, #else, #endif, etc.

	*Type		int, long, char, etc.
	 StorageClass	static, register, volatile, etc.
	 Structure	struct, union, enum, etc.
	 Typedef	A typedef

	*Special	any special symbol
	 SpecialChar	special character in a constant
	 Tag		you can use CTRL-] on this
	 Delimiter	character that needs attention
	 SpecialComment	special things inside a comment
	 Debug		debugging statements

	*Underlined	text that stands out, HTML links

	*Ignore		left blank, hidden  |hl-Ignore|

	*Error		any erroneous construct

	*Todo		anything that needs extra attention; mostly the
			keywords TODO FIXME and XXX





char -> matches 


### Harder

colorize stuff like `#`

`#` is not a keyword (`h: iskeyword`) so we need a regex:

    syntax match potionComment "\v#.*$"

`\v`: use very magic mode. Always use.
