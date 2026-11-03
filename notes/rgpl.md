# RGPL (a licence idea)

The owner, 2026-10-04, verbatim:

> in the RGPL. fan-artists and copyright rulebreakers should be able to
> sue. If the person wants to defend the copyright, they have to pay to
> make the art suitably different. They will be compensated with the
> ability to buy the artwork in question.
>
> at all times, it must have proper credits and references to prior art.
> fanfiction kills the copyright industry. torrenting kills the movie
> industry. Do fewer films get made? No. They are for all of us.

The owner, 2026-10-21, verbatim (while parking issue 920, the legendary
friends, because they are Blizzard's characters). Not yet in the RGPL
draft's text (`/home/ritz/programming/ai-stuff/RGPL`, which as of this
date adds only "our clause", section 13, and the reports clause, section
14, to the AGPL):

> this is sorta true. In the RGPL I think? we say that if you use works to
> create your work, the original authors must maintain full control over
> the version of the software that includes their work. Or something to
> that effect, the idea was that via the license, until we've generated
> everything to make the systems and product entirely our own, Blizzard
> would have the same rights to it that we do (except they can't withdraw
> our rights, they are equal in their integrity). The idea is, we'd create
> auto-generators (and more importantly, skill files and such for creating
> such generators) that replace all of the assets in the game. Until we do,
> anything we make (and display publically, which is everything in this
> particular project but it could theoretically be kept private) must be
> owned by Blizzard for the use with this product, project, or software
> system. So like, if I make a custom character (like Sargobras) then
> Blizzard in this project would be able to use Sargobras with this system.
> They could even make him do things that he wouldn't do, but that's on
> them if they want to invite his ire. But they wouldn't be able to use him
> or his likeness in for example Diablo or Hearthstone, and they wouldn't
> be able to use it in the current, live version of World of Warcraft
> either. The idea is we'd give them the development history, and a neat
> toy that is 99% of the way to a full new game (assuming we complete it of
> course) and they can sell it or whatever but they can't update or change
> it except for non-content based reasons like compatibility or security
> patches. Also they have to follow the rules of the RGPL while using it
> like it must be able to deliver its source-code over the network using
> r-mail (without a third party inbetween).

Questions this raised for the licence text, and the owner's answers the
same day (engineering notes, not legal advice):

1. ~~One party restricted?~~ The draft's core (from the AGPL) gives every
   recipient the freedom to change the work, and "no content changes" would
   have bound Blizzard alone. **Withdrawn by the owner:** "we shouldn't
   restrict Blizzard in that way, my bad. They can do whatever they want
   with it, but they should treat it well and with respect!" So Blizzard
   gets the same freedoms as every other recipient, and the respect is
   asked, not enforced (as the preamble asks it of everyone: "It states
   what the author of the work asks").
2. **A grant is not a permission.** The licence can give Blizzard rights in
   what we made; it cannot make our use of Blizzard's assets allowed. The
   owner: "yes this is why we aren't selling the game until it's 100% our
   own assets."
3. **The line where the shared period ends.** The owner: "yep, that's the
   line, and it includes things like patterns too so quest dialogue or
   terrain meshes. Also we have to make gameplay that is suitably
   distinct, such that the difference between 3.3.5a WotLK World of
   Warcraft is about as different to the product we're creating as, say,
   Wildstar, SW TOR, or some other contemporary game is distinct." So the
   project is its own when:
   - **no Blizzard asset is drawn**: the custom client's count by source
     (its docs/012: "blizzard", "pack", "server") reads zero for
     "blizzard" over a full playthrough;
   - **no Blizzard pattern is used**: quest dialogue, terrain meshes and
     other content shaped from theirs (data the server loads, such as the
     world database's text and the extracted maps) count as borrowed too,
     and need their own counter (where each server-side row and map file
     came from);
   - **the gameplay is distinct** from 3.3.5a WotLK by about as much as
     WildStar or Star Wars: The Old Republic is. Asked whether the combat
     rules underneath must then be replaced too, the owner (2026-10-21):
     "the end result has to be suitably distinct, as compared to it's
     contemporaries. That should be all we say on the matter. The
     judgement is in the comparison, not in our strict wording." So no
     list of required differences is written: the test is the finished
     game set beside its contemporaries.

### Section 7, explained (asked by the owner)

"Does that mean that someone could receive the software, prune out 99% of
the license, and change two variables, then say it's theirs and anyone can
use it with no restriction?" No. Section 7 (kept from the AGPL) lets a
recipient remove only **further restrictions**: extra terms that someone
bolted onto the licence from outside ("additional terms", like "do not
share this source"). The licence's own text cannot be removed. Section 4
and 5 require that every copy and every changed version keep the licence
intact and be passed on under it, whole; section 10 makes every
recipient's licence come from the original authors, not from whoever
handed it on. Someone who changes two variables owns their two changes,
and must pass on the whole work, changes included, under the RGPL. That is
why "our clause" was written into the core (section 13) instead of being
added as an extra term: an extra term would have been removable under
section 7; a core clause is not.
