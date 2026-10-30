# 093-alterac-weather-page

## What made it
- scripts/generate-weather-page (seed 2026, 3 hours), opened at #t=400 (photographed: headless Firefox, 1400 wide, the whole page, file:///mnt/kaun/wow-chat-2026/docs/HTML/alterac-weather.html#t=400)
- Commit: 0d91b15 (with uncommitted changes to its sources)
- Filed: 2026-10-30 11:07 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/generate-weather-page` | 444bed88b20d1aaa |
| `patches/B036-mod-buddies/mod-buddies/src/buddies_weather_deck.h` | 4872d53c1518ed67 |
| `patches/B036-mod-buddies/mod-buddies/src/buddies_weather_storm.h` | f7ada2356f504898 |

## What changed since the previous picture
- `scripts/generate-weather-page`: first picture that names it
- `patches/B036-mod-buddies/mod-buddies/src/buddies_weather_deck.h`: first picture that names it
- `patches/B036-mod-buddies/mod-buddies/src/buddies_weather_storm.h`: first picture that names it

## What it shows
The weather page (docs/HTML/alterac-weather.html) opened at step 400, 2 hours 13 minutes into a 3-hour playback with seed 2026. Top: the title and a line on what it plays. Then the controls: a Play button, the time slider at about three quarters, and "2h 13m: fine, 64%". A key of the seven kinds' colours. The middle panel: the deck's turns left to right as coloured bands, each a peak (the strength's half sine, faint behind as the turn's full height), three full decks and more, no colour twice in a row, a dark line at the current moment. The bottom panel: Alterac Valley's 548 cells (the game's x along the valley left to right), grey where the storm has not been, green where it has, darker where it has been longest, spread over the whole length; the storm a dark disc (the 60-yard downpour) inside a ring (the 90-yard edge), on the valley's lower left.

## The story so far
The owner asked for Alterac Valley's shared weather (a deck: "non deterministic yet still equally distributed") and a storm "always intensely downpowering"; the rain became slush. On the push toward the next compile, the deck and the storm were built as plain arithmetic with tests (exact shares over 10,000 decks; the storm over a simulated day, never leaving the valley, every tenth of it 0.88 to 1.11 of its share), the server side compiler-checked to wait for the compile, and this page drawn from the tests' own output so it can't disagree with the server.
