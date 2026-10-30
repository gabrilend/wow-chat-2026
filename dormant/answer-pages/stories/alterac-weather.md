title: Alterac Valley's Weather
subtitle: One sky for every match, and a storm that wanders it
part: Rules and Views
state: planned; this page is the plan, and the simulator is built once the owner approves it
issues: 921 921a 921b
gifs: 5a 5b 5c 5d 5e

The owner, 2026-10-29: "Can we make issue files for a feature where the
Alterac Valleys on the server all share the same weather? And it
oscillates in a pattern (is collages) that is non deterministic yet still
equally distributed. A storm cloud should wander across the map and
always be intensely downpowering"

## One sky

gif: 5d

Every Alterac Valley match on the server shows the same weather at the
same moment: one clock for the whole server. A match that opens, and a
player who arrives in one, is given the weather of that moment. It sits
behind a switch, `Buddies.AlteracWeather`, off until turned on.

## The deck

gif: 5a

The weather kinds are dealt like a shuffled deck: fine, fog, light snow,
snow, heavy snow, light slush and slush. Each kind comes once a deck, in a
fresh random order each time, from a seed nobody can predict. Over any
whole number of decks every kind has had exactly the same time: that is
the "non deterministic yet still equally distributed". A new deck never
opens with the kind the last one closed on. Each turn lasts six minutes,
swelling from nothing to full and fading back.

## Slush

gif: 5b

The owner: "the rain freezes to slush." The game has no sleet, so a slush
turn is drawn from rain and snow: it opens as rain, trades back and forth
between rain and snow through its middle, and closes as snow.

## The storm

gif: 5c

One storm cell, the same in every match, drifts at a walking pace, two
yards a second. It keeps its heading for a while and turns gently,
turning back from the valley's edges. Within 60 yards of it everyone is
in the heaviest rain the game shows, with thunder, always; from 60 to 90
yards it fades into the shared sky. The game sends weather for a whole
zone at once, so the storm is drawn by sending each player under it their
own weather.

## Even over time

gif: 5e

The storm leans toward the parts of the valley it has visited least
lately, so over a long match every part has had its share. The same idea
as the deck, in space: unpredictable from moment to moment, even over
time.

## What is built once approved

A simulator: the deck dealt on a timeline with each turn's swell and
fade, slush turns trading rain and snow, and the storm wandering the real
valley map with a heat map of where it has been, with sliders for turn
length, storm size and pace.

## The questions

questions:
