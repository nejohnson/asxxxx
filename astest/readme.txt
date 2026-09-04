                        ASxxxx Test Harness

astest runs the ASxxxx assemblers and ASLink over a corpus of test
cases and compares what they produce with what they are expected to
produce.  It reports a pass or a failure for each case and exits
non zero if any case failed, so that it can be used from a makefile.

    make check          run every case
    make bless          record the current output as the expected output
    make check-clean    remove the working directories

    astest <case> ...   run only the named cases

Building it needs no CPU target:  the corpus is assembled with
ascheck, the machine independent assembler, so 'make check' builds
only ascheck, aslink, asxscn and astest.


                        A Test Case

A case is a directory under astest/cases holding a script named
run.tst and the expected output of the tools that script runs.  The
manifest astest/tests.lst lists the cases to run, one id per line,
'#' beginning a comment.  A case id is at most 8 characters:  the
working directory it creates must keep to an 8.3 name.

Each line of run.tst is a verb, white space, and the rest of the
line as its argument:

    name    <text>          description shown in the summary
    src     <dir>           input directory, relative to the tree root
    tool    <name>          assembler to use, default ascheck
    copy    <file>          copy a file into the working directory
    asm     <opts> <base>   assemble <base>.asm
    link    <opts> ; <...>  link;  ';' separates command file lines
    scan    <opts> <file>   check a listing with asxscn
    gold    <file>          compare against <file>.gold
    goldbin <file>          compare byte for byte, no normalisation
    absent  <file>          require that a file was not produced
    expect  <n>             exit status required of the next tool

In a link the ';' separates one line of the command file from the
next, so that an option and its argument stay together:  aslink
reads "-a name=expr" as one line, not as two.

'%w' in an argument expands to the working directory and '%s' to
the input directory, for the options that need a path rather than a
bare name:  a bare name in a command file is resolved relative to
that file, but a file the linker creates is resolved relative to the
directory the linker was run from.

Nothing is quoted.  The quoting rules of the Bourne shell, cmd.exe
and COMMAND.COM do not agree, so a path containing a space is
refused at startup instead.


                        Expected Output

Two things in the output of a tool change between two runs of the
same test:  the program version and the time of the run, both in the
page heading written by newpag().  A linker map also names the files
it was given, and the directory those were found in depends on where
the test was run from.  astest removes exactly those, and nothing
else, from the produced file and from the expected file alike.  The
expected files are stored already normalised, so a difference
between two of them is always a real one and 'diff' on them is
worth reading.

'make bless' writes the current output as the expected output.  It
is a separate target and is never reached from 'make check'.

    A blessed file records what the tools do today, not what they
    ought to do.  Before trusting one, read it against the test
    source:  the sources under ascheck carry their expected values
    in comments, and several carry a memory map in the header.

    A commit that blesses must contain only .gold files, and its
    message must say why each changed line changed.  A golden that
    moved is either a fault that has been fixed or a fault that has
    been introduced, and the commit is where that is decided.


                        Portability

astest is written to build wherever ASxxxx builds.  Two things are
platform dependent and both are in astest.h:  how a directory is
created, and how the return value of system() is decoded.  There is
no portable way to tell whether system() returns a wait status or a
raw exit code, so the platforms ASxxxx is built on are listed
explicitly.  A compiler outside that list would silently mis-read
every result, so before running any case astest runs asxscn with no
arguments, which exits 1, and stops if it does not read back as 1.

'>' is the only redirection every supported command interpreter
accepts.  '2>' is understood by the Bourne shell and by cmd.exe but
not by COMMAND.COM, so on MS-DOS the diagnostics of a tool are left
on the console rather than captured.

On MS-DOS keep the tree within two directory levels of the drive
root:  a command line here reaches about 84 characters and the
limit is 127.
