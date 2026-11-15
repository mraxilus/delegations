# Notice

The file `articles.nim` in this folder holds the text of articles of the lojban Wikipedia,
at <https://jbo.wikipedia.org>. The Wikipedia releases its text under the Creative Commons
Attribution-ShareAlike licence (CC BY-SA), now version 4.0, at
<https://creativecommons.org/licenses/by-sa/4.0/>.

Text written before the Wikipedia moved to version 4.0 came under version 3.0. Version 3.0
lets an adaptation be shared under a later version. So this folder is not under the licence
of the repository, and it is distributed under CC BY-SA 4.0.

These are the changes:

- The API of the Wikipedia gives the plain text of each article, without its markup.
- Each heading is left out, and each line of the text is one paragraph.
- The text of each paragraph does not change.

The command `nim r tools/build.nim wikipedia <directory>` writes this folder. Each article
names its authors in its history. These are the articles, each with the revision that the
text comes from, and its history:

- `cmaci`, revision 114271:
  <https://jbo.wikipedia.org/w/index.php?oldid=114271>,
  <https://jbo.wikipedia.org/w/index.php?curid=19&action=history>
- `eliogabalus`, revision 107948:
  <https://jbo.wikipedia.org/w/index.php?oldid=107948>,
  <https://jbo.wikipedia.org/w/index.php?curid=4044&action=history>
- `lo jbobau`, revision 115608:
  <https://jbo.wikipedia.org/w/index.php?oldid=115608>,
  <https://jbo.wikipedia.org/w/index.php?curid=70&action=history>
