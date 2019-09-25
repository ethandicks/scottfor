# scottfor
Game Engine for Scott Adams' text adventures, written in FORTRAN

This is a work in progress.  There are numerous game engines ("drivers")
for Scott Adams' text adventures, written in BASIC, 6502 assembler, Z-80
assembler, Perl, C, and more.  None of these are suitable for vintage
platforms like the PDP-8.  As an intermediary step, this is a stab at
a game engine in FORTRAN.  Since CHARACTER variables were first introduced
in FORTRAN 77, that's the first target.

Present stage of completeness: reading in game header, action table,
vocabulary words (verbs and nouns), and room directions and descriptions.

TBD: read messages, items, action comments, and trailer; accept user
input; parse user input; loop over action table; perform condition tests;
perform actions; main loop housekeeping; and load and save routines

Notable challenges: room descriptions and messages can span multiple
lines in the game database file including embedded newlines.  This
requires a dynamic string read process looking for the terminating
double-quote char and concatenation of the multiple segments.


