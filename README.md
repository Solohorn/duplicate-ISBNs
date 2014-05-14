duplicate-ISBNs
===============

Perl script to list duplicate ISBNs

COSUGI Day of Coding
May 14, 2014

Original request:
We need a report that can find Duplicate ISBNs (either within the same record or in different records) and has limiting options like those in the List bibliography report. We'd also like a report which would check for duplicate entries in any field specified, not just the 020 (or 022 if you want to include ISSNs). Such as report numbers, publisher's numbers, EAN, UPC, etc.
http://enh.sdusers.net/forum/viewtopic.php?f=79&t=4704

Started working on this as an ISBN duplicate checking program. Rather than have this run as a Sirsi report, we would run this on an exported MARC file

Issues with “duplicate” ISBNs:
1) One bib record can have many ISBNs listed
2) The vol. 1 ISBN often listed in the vol. 2 record. This may be useful if you want to consolidate vol. 1 and vol. 2 in  a single bib. record. You might not want to do this for some materials (e-books).
3) Similar to the vol. 1 … vol. n issue, there may also be an ISBN for the set as a whole as well as the ISBNs for the individual parts in the set.
4) 020 is repeatable, and ISBN numbers can be found in $a or $z.
5) There are sometimes additions after the ISBN proper [e.g., (pbk.)]
6) Not all records have an ISBN.
7) Not all books have an ISBN.

Features:
The script flags invalid ISBNs.
The script lists ISBNs that appear in more than one record.
Flags duplicate ISBNs within a single record.

Options:
The unique key is assumed to be in 9xx$a or 001. The 001 is the default.

TO DO:
Option to check ISBNs in 776$z.
Provide options to check for duplicate ISSN, Pub. No., etc.
Option to ignore numbers in 020$z
Does not flag duplicate ISBNs within a record[?]
