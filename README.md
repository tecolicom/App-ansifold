[![Actions Status](https://github.com/tecolicom/App-ansifold/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/tecolicom/App-ansifold/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/App-ansifold.svg)](https://metacpan.org/release/App-ansifold)
# NAME

ansifold/ansicolrm/ansicut - fold/colrm/cut command handling ANSI terminal sequences

# SYNOPSIS

    ansifold [ options ]

      -w#    --width=#                Folding width (default 72)
             --boundary=word|space    Fold on word boundary
             --padding[=#]            Padding to margin space
             --padchar=_              Default padding character
             --prefix=string          Set prefix string (default empty)
             --autoindent=pattern     Set auto-indent pattern
             --keepindent             Preserve indent string
             --ambiguous=narrow|wide  Unicode ambiguous character handling
      -p     --paragraph              Print extra newline
      -r     --refill                 Join paragraph into single line first
             --separate=string        Set the output separator string (default newline)
      -n     --nonewline              Same as --separate ''
      --lb=# --linebreak=mode         Line-break mode (all, runin, runout, none)
             --runin=#                Run-in width (default 4)
             --runout=#               Run-out width (default 4)
             --runlen=#               Set run-in and run-out both
             --splitwide[=#]          Split in the middle of wide character
      -s     --smart                  Same as --boundary=word --linebreak=all
             --crmode                 Treat CR as line separator for fill
      -x[#]  --expand[=#]             Expand tabs
             --tabstop=n              Tab-stop position (default 8)
             --tabhead=char           Tab-head character (default space)
             --tabspace=char          Tab-space character (default space)
             --tabstyle=style         Tab expansion style (shade, dot, symbol)
             --colrm start [ end ]    colrm(1) command compatible
      -c#    --cut list               cut(1) command compatible
      -h     --help                   Show help message
      -v     --version                Show version

    ansicolrm [ options ]

    ansicut -c list

# VERSION

Version 1.32

# DESCRIPTION

**ansifold** is a [fold(1)](http://man.he.net/man1/fold) compatible command utilizing
[Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) module, which enables to handle ANSI terminal
sequences.

**ansicolrm** works like [colrm(1)](http://man.he.net/man1/colrm) command.  This is an alias for
**ansifold** command and works exactly same except option **--colrm** is
enabled by default.

**ansicut** works like [cut(1)](http://man.he.net/man1/cut) command. This is an alias for
**ansifold** command and works exactly same except default output
separator string is set as empty by default.  Support only **-c** (or
**--cut**) option of the original [cut(1)](http://man.he.net/man1/cut) command.

## FOLD BY WIDTH

**ansifold** folds lines in 72 column by default.  Use option **-w** to
change the folding width.

    $ ansifold -w132

Single field is used repeatedly for the same line.

With option **--padding**, remained columns are filled by padding
character, space by default, or specified by optional value like
`--padding=_`.  Default padding character can be set by **--padchar**
option.

**ansifold** handles Unicode multi-byte characters properly.  Option
**--ambiguous** takes _wide_ or _narrow_ and it specifies the visual
width of Unicode ambiguous characters.

If the last character is full-width and must be wrapped in the middle
of it, it is wrapped just before the character.  If padding is
specified, then one padding character is inserted.  If you really want
to keep the wrapping position, use the `--stripwide` option.

## TERMINAL WIDTH and CALCULATION

If the width argument begins with `=`, it is interpreted as an RPN
(Reverse Polish Notation) expression with the terminal width as the
initial value.  Therefore,

    ansifold -w=

will wrap at the width of the terminal, and

    ansifold -w=2/

will wrap at half the width of the terminal.

## MULTIPLE WIDTH

Unlike the original fold(1) command, multiple numbers can be
specified.

    $ LANG=C date | ansifold -w 3,1,3,1,2 | cat -n
         1  Wed
         2   
         3  Dec
         4   
         5  19

With multiple fields, unmatched part is discarded as in the above
example.  So you can truncate lines by putting comma at the end of
single field.

    ansifold -w80,

Option `-w80,` is equivalent to `-w80,0`.  Zero width is ignored
when seen as a final number, but not ignored otherwise.

If the data is shorter and there is no corresponding string for the
field, an empty string is returned.  If the padding option is
specified, the field is padded to the given width.

## NEGATIVE WIDTH

Negative number fields are discarded.

    $ LANG=C date | ansifold -w 3,-1,3,-1,2
    Wed
    Dec
    19

If the final width is negative, it is not discarded but takes all the
rest instead.  So next commands do the same thing.

    $ colrm 7 10

    $ ansifold -nw 6,-4,-1

Option `--width -1` does nothing effectively.  Using it with
**--expand** option implements ANSI/Unicode aware [expand(1)](http://man.he.net/man1/expand) command.

    $ ansifold --expand --width -1

This can be written as this.

    $ ansifold -xw-1

## NUMBERS

Number description is handled by [Getopt::EX::Numbers](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ANumbers) module, and
consists of `start`, `end`, `step` and `length` elements.  For
example,

    $ echo AABBBBCCCCCCDDDDDDDDEEEEEEEEEE | ansifold -w 2:10:2

is equivalent to:

    $ echo AABBBBCCCCCCDDDDDDDDEEEEEEEEEE | ansifold -w 2,4,6,8,10

and produces output like this:

    AA
    BBBB
    CCCCCC
    DDDDDDDD
    EEEEEEEEEE

## SEPARATOR/TERMINATOR

Option **-n** eliminates newlines between columns.

    $ LANG=C date | ansifold -w 3,-1,3,-1,2 -n
    WedDec19

Option **--separate** set the output separator string.

    $ echo ABCDEF | ansifold --separate=: -w 1,0,1,0,1,-1
    A::B::C:DEF

Option **-n** is a short-cut for `--separate ''`.

Option **--paragraph** (or **-p**) print extra newline after each line.
This is convenient when a paragraph is made up of single line, like
microsoft word document.  The **-p** option can be repeated multiple
times and will output that many newline characters.

## PREFIX

### **--prefix**=_string_

If a string is given by **--prefix** option, that string is inserted at
the beginning of each folded text.  This is convenient to produce
indented text block.  Because the first line is not affected, insert
appropiate prefix if necessary.  Originally made for
[App::Greple::frame](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aframe) module.

### **--autoindent**=_pattern_

An experimental **--autoindent** option takes a regex pattern for the
indent label, and set the prefix string as a space string of that
label length.  For example, command `ps auxgw` produce very long line
output and you may want to fold `COMMAND` portion with appropiate
indentation.  In this case use **--autoindent** option like this:

    $ ps axgw | ansifold --autoindent '.*TIME (?=COMMAND)' -w= --boundary=word
      PID   TT  STAT      TIME COMMAND
        1   ??  Ss   817:25.87 /sbin/launchd
      354   ??  S      4:30.01 /System/Applications/TextEdit.app/Contents/
                               MacOS/TextEdit
      522   ??  Ss     2:50.67 /System/Library/PrivateFrameworks/Uninstall.
                               framework/Resources/uninstalld

### **--keepindent**

If the `--keepindent` option is specified, the string matched by
`--autoindent` is inserted at the beginning of the line rather than
indenting with spaces.

## REFILL

### **--refill**, **-r**

Option **--refill** (or **-r**) makes the command to run in paragraph
mode, which read consecutive non-blank lines at once, and join them
into single line before processing.  So all paragraphs are reformatted
by new text width.  You can use this with **--autoindent** option.

When joining lines, newlines between full-width characters (Japanese,
Chinese) are simply removed without adding space.  Korean (Hangul) is
treated like ASCII text and joined with space.

Option **-rw-1** will just fill paragraphs without reformatting.

### **--crmode**

Option **--crmode** is designed to work with [App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee)
module's **--crmode** option.  It does the following:

- Joins text separated by carriage return (CR) characters.  For ASCII
text, CR is replaced with a space.  For full-width characters (e.g.,
Japanese and Chinese), CR between them is simply removed without
adding space.  Korean (Hangul) is treated like ASCII text and joined
with space.
- Sets the output separator to CR (equivalent to `--separate '\r'`),
so that the folded lines are separated by CR instead of newline.
This allows tee's **--crmode** to convert them back to newlines.

Example with [App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee):

    greple -Mtee ansifold -sw80 --crmode -- --crmode ...

# LINE BREAKING

Line break adjustment is supported for ASCII word boundaries.  As for
Japanese, more complicated prohibition processing is performed.  Use
option **-s** to enable everything.

## **--boundary**=_word_|_space_

This option prohibit breaking line in the middle of ASCII/Latin word.
Context of word is defined by option value; _word_ means
alpha-numeric sequence, while _space_ means simply non-space
printables.

## **--linebreak**=_all_|_runin_|_runout_|_none_, **--lb**=...

Option **--linebreak** takes a value of _all_, _runin_, _runout_ or
_none_.  Default value is _none_.

When **--linebreak** option is enabled, if the cut-off text start with
space or prohibited characters (e.g. closing parenthesis), they are
ran-in at the end of current line as much as possible.

If the trimmed text end with prohibited characters (e.g. opening
parenthesis), they are ran-out to the head of next line, provided it
fits to maximum width.

## **--runin**=_width_, **--runout**=_width_

## **--runlen**=_width_

Maximum width of run-in/run-out characters are defined by **--runin**
and **--runout** option.  Default values are 4.

Option **--runlen** set both run-in/run-out width at once.

## **--splitwide**\[=_lefthalf_\[_righthalf_\]\]

If it becomes necessary to break in the middle of a wide character,
split the character into left and right half.  Replacement characters
are `\N{LEFT HALF BLACK CIRCLE}` (`◖`) and `\N{RIGHT HALF BLACK
CIRCLE}` (`◗`) by default.

If a parameter is given, the first character is used as the left half.
The next character, if any, is used as the right half, otherwise the
first character is used.

## **--smart**, **-s**

Option **--smart** (or simply **-s**) set both **--boundary=word** and
**--linebreak=all**, and enables all smart text formatting capability.

Use option **--boundary=space** if you want the command to behave more
like **-s** option of [fold(1)](http://man.he.net/man1/fold) command.

# TAB EXPANSION

## **--expand**

Option **--expand** (or **-x**) enables tab character expansion.

    $ ansifold --expand

Takes optional number for tabstop and it precedes to **--tabstop**
option.

    $ ansifold -x4w-1

If the command is executed with the name `ansiexpand`, it works as if
the **--expand** option were given, and set default folding width to
\-1.  [App::ansiexpand](https://metacpan.org/pod/App%3A%3Aansiexpand) is a bit more sophisticated and we recommend
using that one rather.

## **--tabhead**, **--tabspace**

Each tab character is converted to **tabhead** and following
**tabspace** characters (both are space by default).  They can be
specified by **--tabhead** and **--tabspace** option.  If the option
value is longer than single characger, it is evaluated as unicode
name.  Next example makes tab character visible keeping text layout.

    $ ansifold --expand --tabhead="MEDIUM SHADE" --tabspace="LIGHT SHADE"

## **--tabstyle**

Option **--tabstyle** allow to set **--tabhead** and **--tabspace**
characters at once according to the given style name.  Select from
`dot`, `symbol` or `shade`.  Styles are defined in
[Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) library.

    $ ansifold --expand --tabstyle=shade

# COLRM COMPATIBLE

## **--colrm** \[ _start_ \[ _end_ \] ... \]

Option **--colrm** takes [colrm(1)](http://man.he.net/man1/colrm) command compatible arguments.

Since the output separator string is not set, use the **-n** option to
get the same result as the [colrm(1)](http://man.he.net/man1/colrm) command; when invoked as
**ansicolrm** command, the separator string is set to the empty by
default.

Next command behave exactly like `colrm start end` and takes care of
ANSI terminal sequences.

    $ ansifold -n --colrm start end

    $ ansicolrm start end

Unlike standard [colrm(1)](http://man.he.net/man1/colrm), _start_ and _end_ can be repeated as
many times as desired.  Next command removes column 1-3 and 7-9, and
produces `4560` as a result.

    $ echo 1234567890 | ansifold -n --colrm 1 3 7 9
           ^^^   ^^^

# CUT COMPATIBLE

## **--cut** list ...

## **-c** list ...

Option **--cut** (or **-c**) takes [cut(1)](http://man.he.net/man1/cut) command compatible
arguments.

Since the output separator string is set, use the **-n** option to get
the same result as the [cut(1)](http://man.he.net/man1/cut) command; when invoked as **ansicut**
command, the separator string is set to the empty by default.

Next command behave exactly like `cut -c list` and takes care of ANSI
terminal sequences.

    $ ansifold -n -c list ...

    $ ansicut -c list ...

Next command retrieve column 4-6,9- and produces `45690` as a result.

    $ echo 1234567890 | ansifold -nc 4-6,9-
              ^^^  ^^

Unlike [cut(1)](http://man.he.net/man1/cut)'s **-c** option, parameter number is taken as screen
columns of the terminal, rather than number of logical characters.

# FILES

- `~/.ansifoldrc`

    Start-up file.
    See [Getopt::EX::Module](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AModule) for format.

# INSTALL

## CPANMINUS

    $ cpanm App::ansifold

# SEE ALSO

[ANSI Tool collection](https://github.com/tecolicom/ANSI-Tools)

[ansifold](https://github.com/tecolicom/App-ansifold)

[ansiexpand](https://github.com/tecolicom/App-ansiexpand)

[ansicolumn](https://github.com/tecolicom/App-ansicolumn)

[Text::ANSI::Fold](https://github.com/tecolicom/Text-ANSI-Fold)

[Text::ANSI::Fold::Util](https://github.com/tecolicom/Text-ANSI-Fold-Util)

[Getopt::EX::Numbers](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ANumbers)

[App::Greple::tee](https://github.com/kaz-utashiro/App-Greple-tee)

[https://www.w3.org/TR/jlreq/](https://www.w3.org/TR/jlreq/):
Requirements for Japanese Text Layout,
W3C Working Group Note 11 August 2020

[fold(1)](http://man.he.net/man1/fold), [colrm(1)](http://man.he.net/man1/colrm), [cut(1)](http://man.he.net/man1/cut)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright ©︎ 2018-2025 Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
