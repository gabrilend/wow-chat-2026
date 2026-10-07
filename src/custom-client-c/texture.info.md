# texture

*Written by `scripts/generate-custom-client-info` from `texture.h`; don't edit, re-run it.*

texture.h (issue 173u) - the game's pictures onto the graphics card

For a general audience: most of the game's pictures are stored already
compressed in the graphics card's own block format (DXT: 4 x 4 pixels in
8 or 16 bytes), with every smaller copy made in advance. Unpacking them
on the processor and sending the plain pixels costs time at load and 4
to 8 times the card's memory. This sends compressed pictures as they
are, every smaller copy included, and unpacks only the others (palette
and plain pictures, as blp.c reads them) and makes their smaller copies
on the card. Either way the picture is smoothed between its copies and
repeats past its edges.

The BLP2 header (blp.h): 8 encoding (2: DXT), 10 alpha kind (0 DXT1,
1 DXT3, 7 DXT5), 12 width, 16 height, 20 where each copy starts (16
words), 84 how long each is.

## What it offers

- `int texture_from_blp(const unsigned char *s, size_t len, Texture2D *out, char *why, int why_len);`
  The picture in `s` (a whole .blp file) on the card. 0, or 1 with `why`.
- `void texture_bytes(size_t *sent, size_t *unpacked);`
  How many bytes of pictures have gone to the card this way, and how many
  they would have taken unpacked (for the picture report).
