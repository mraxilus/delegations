# Notice

The file `examples.nim` in this folder holds lojban text from The Complete Lojban Language,
version 1.1, generated 2016-08-26. The Logical Language Group publishes the book at
<https://lojban.org/publications/cll/cll_v1.1_xhtml-section-chunks/>.

The text is extracted from the book, and so it is a modified version of the book. These are
the modifications:

- Only the numbered examples are kept, and of each example only the lines of lojban text.
- The cells of a row of a table are joined by one space.
- A no-break space becomes a space, and a run of white space becomes one space.
- The markup of each line is removed.

The command `nim r tools/build.nim cll <directory>` writes this folder from saved pages of
the book. This folder is not under the licence of the repository. It is distributed under
the terms of the notice that follows, which Section 1.8 of the book gives:

> Copyright © 1997 by The Logical Language Group, Inc. All Rights Reserved.
>
> Permission is granted to make and distribute verbatim copies of this book, either in electronic or
> in printed form, provided the copyright notice and this permission notice are preserved on all
> copies.
>
> Permission is granted to copy and distribute modified versions of this book, provided that the
> modifications are clearly marked as such, and provided that the entire resulting derived work is
> distributed under the terms of a permission notice identical to this one.
>
> Permission is granted to copy and distribute translations of this book into another language,
> under the above conditions for modified versions, except that this permission notice may be stated
> in a translation that has been approved by the Logical Language Group, rather than in English.
>
> The contents of Chapter 21 are in the public domain.
>
> For information, contact: The Logical Language Group, 2904 Beau Lane, Fairfax VA 22031-1303 USA.
> Telephone: 703-385-0273. Email address: llg-board@lojban.org. Web Address: http://www.lojban.org.
