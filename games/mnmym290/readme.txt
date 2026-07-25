
				  Mine Mayhem

			   Copyright 2006 Jason Hood

				  Version 2.90

				    Freeware


System Requirements: 386+,
		     2 MB RAM (may work with less),
		     VESA 640x480x256,
		     Mouse,
		     Sound Blaster (compatible) for sound effects.

Installation: Unzip it into it's own directory (use -d with pkunzip).
	      If you have a maths co-processor emu387.dxe can be deleted.

Upgrading: The time format has changed, so you will need to delete your
	   "*.tym" files.

Type "mine" to run the game.


Changes from v2.11:

  Bugs:
    update the difficulty when only changing mines;
    time will be limited to between 0.001 and 999.999, inclusive;
    "both" completed percentage (and made "either" the same as "both");
    average speed (use true average, rather than average time);
    max out the mine and space counters at 999.

  General:
    changed Squares and Hexagons Beginner game to 9x9;
    right button can mark around an opened tile;
    cannot mark a tile if a tile around it already has all its marks;
    cannot mark before starting;
    the "dead" mine no longer counts as a flag;
    hint options, to show which tiles can be marked and opened;
    display 3BV, 3BV/s and click efficiency after a game;
    right-clicking the face button when finished will restart the same game;
    added a slight delay before right-clicking will start a new game;
    custom games must be explicitly saved before records are kept;
    changed order of custom games (width, then height, then mines);
    changed minimum number of mines to 1;
    reduced minimum Squares and Hexagons games to 5x5;
    predefined games can be played as custom games (but not saved);
    the game menu button will only toggle between clear and cross;
    no options can be changed during a game;
    improved hexagon tile recognition;
    allow manual marking when using automatic marking;
    allow unmarking when using automatic opening;
    display a "bland" face if the game does not keep records.

  Cross:
    best times are no longer kept;
    only allow clicking on known tiles (as determined by the hints);
    display the number of left and right clicks, instead of spaces and mines;
    blank tiles will only open surrounding tiles with the automatic options;
    use the millisecond display to indicate the ideal distance to the end.

  Configuration:
    removed "Clear-Around Button", always use left button;
    added "Mine Counter" to adjust numbers according to flags;
    Starting Condition:
      "One displacement" becomes "Displace" and applies to any tile that is
	a "guess";
      "Automatic" becomes "Blank", which guarantees the first tile will not
	 have a mine or be surrounded by a mine, and then acts as "Displace";
      added "Perimeter", which will open the entire perimeter first;
    removed "Marks";
    added "Marks counter", which uses a mine count instead of a flag;
    added "Logical", which positions mines so guessing is not required.

  Times:
    removed the slowest five times, increase to the ten fastest;
    use icons to represent options, added tracking and automatic clearing;
    keep the date of the first game won;
    removed name, score and deviation, added 3BV, rating and 3BV/s;
    keep separate records for best 3BV/s;
    statistics display, including games lost;
    the current record highlight will be preserved after changing tables;
    use a single character to indicate each option.


Changes from v2.10:

  Highlighting current record time works again.


Changes from v2.00:

  Game Type moved to the menu;
  added "Swap Stereo" option;
  added "Tracking" option;
  added "Automatic Clearing" option;
  F12 will save the board as a bitmap;
  Clear games display percentage completed (using milliseconds);
  Custom games can be deleted;
  added Speed and Score options to time display (Clear game only);
  times can be cleared (and saved as text);
  save best times as text;
  displaying times from a Random game will no longer create a Custom game.


Redistribution: Distribute freely.  I would like to be informed if it is put
		on a CD-ROM collection (permission is not required to do so).

-------

CWSDPMI is Copyright (C) 1995-2000  Charles W Sandmann (sandmann@clio.rice.edu)
				    1206 Braelinn, Sugar Land, TX 77479

The source and/or updates are available at:
ftp://ftp.delorie.com/pub/djgpp/current/v2misc/csdpmi*.zip

-------

Jason Hood, 16 December, 2006.
