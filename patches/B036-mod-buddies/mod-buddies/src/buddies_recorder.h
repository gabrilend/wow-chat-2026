/*
 * buddies_recorder.h - boarding recordings: a player's own walk onto a boat
 * or zeppelin, kept and replayed by buddies (issue 617e9).
 *
 * For a general audience: getting onto a ship is fiddly - a gangway, a
 * ramp, a hop over a rail - and the server has no map of a deck. So the
 * owner shows it: a game master types ".buddy record start" on the dock,
 * walks (or jumps) aboard, and types ".buddy record stop". Every step the
 * game reported is kept: where, which way facing, walking or running,
 * jumping, and, once aboard, where on the deck (measured from the ship, so
 * it still fits when the ship has moved). Stepping off is recorded the
 * same way, from the deck to the dock. A buddy that must board picks one of
 * that dock's recordings whose starting spot no other buddy holds, stands
 * there until the ship is in, and walks the recording.
 *
 * The camera is never seen by the server (only the character's facing is),
 * and the model doesn't matter: a bot is moved along the recorded points by
 * the server, not by the client's collision, so any race's recording fits
 * any buddy.
 */

#ifndef MOD_BUDDIES_RECORDER_H
#define MOD_BUDDIES_RECORDER_H

#include "Define.h"
#include <string>

class MotionTransport;
class Player;

// {{{ kinds and step flags
// A recording's kind, from where it started and ended: ashore to the deck
// is an embark, the deck to ashore a disembark.
enum BuddyBoardingKind : uint8
{
    BUDDY_BOARD_EMBARK    = 1,
    BUDDY_BOARD_DISEMBARK = 2,
};

// Each recorded step's flags (one byte in the table).
enum BuddyBoardingStepFlag : uint8
{
    BUDDY_STEP_DECK = 0x01,     // on the deck: x, y, z, o are offsets from the ship, not world yards
    BUDDY_STEP_JUMP = 0x02,     // a jump left from here; jumpXY and jumpZ are its speeds
    BUDDY_STEP_LAND = 0x04,     // a jump or fall landed here
    BUDDY_STEP_WALK = 0x08,     // walking, not running, on the way here
};
// }}}

// {{{ BuddyReplay
// One buddy's place in a recording it is walking. Owned by the crossing's
// trip (buddies_crossing.cpp); only this file reads its fields.
//   id          the recording (0: none chosen)
//   next        the step being walked to while a leg is under way, else the
//               next step to walk to
//   legStarted  game-time ms the current leg began (0: none under way)
//   legLimitMs  how long that leg may take before the replay is called stuck
//   retries     legs re-sent after arriving short (something else moved it)
struct BuddyReplay
{
    uint32 id         = 0;
    uint32 next       = 0;
    uint64 legStarted = 0;
    uint32 legLimitMs = 0;
    uint8  retries    = 0;
};
// }}}

// The start of a chosen recording, in world yards (for an embark: where to
// stand on the dock; for a disembark the start is on the deck and the
// crossing doesn't walk there itself - the replay's first leg does).
struct BuddyBoardingStart
{
    uint32 mapId = 0;
    float  x = 0.0f, y = 0.0f, z = 0.0f, o = 0.0f;
};

// Choose a recording of this kind for this ship at this stop of its route,
// for this buddy: a start no other buddy holds, nearest the buddy first,
// else the nearest held one. Claims it for the buddy (a buddy holds one at
// a time; choosing again lets the old one go). False when the stop has no
// recording of this kind at all.
bool BuddyBoardingPick(uint8 kind, uint32 entry, uint8 stop, Player* bot, BuddyReplay& replay, BuddyBoardingStart& start);

// The buddy's held recording is let go (its trip is over or replanned).
void BuddyBoardingRelease(uint32 buddyGuid);

// One step of walking a recording. `mt` is the ship (docked).
enum class BuddyReplayResult : uint8 { Running, Done, Failed };
BuddyReplayResult BuddyReplayStep(Player* bot, MotionTransport* mt, BuddyReplay& replay, std::string& why);

#endif
