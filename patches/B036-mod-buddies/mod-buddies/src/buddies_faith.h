/*
 * buddies_faith.h - a buddy's faith in each player it might give a buff to
 * (issue 625l, a player's faith; and the short list made on joining): plain
 * data and arithmetic, apart from the server, so it can be tested on its own
 * (tests/buddy-faith/, scripts/test-buddy-faith). Read by the forward pass's
 * choice of whom a chosen-ally buff goes on (buddies_forward_pass.h, Leans).
 *
 * For a general audience: the owner, 2026-10-30, word for word: "if a player
 * has a cooldown ready but they're holding it, then that probably means they
 * want to save for a burn. If we can and it would benefit them, we can save
 * the buddy-bot's buff for the player's burn phase - this is more satisfying
 * than seeing it go to a bot. BUT if the player keeps holding and holding
 * then we can give them a negative malus to the buddy-bot's weight for them
 * for that buff in particular, and at a certain point it'll just make more
 * sense to use it on a buddy-bot instead." And: "every time they hold it
 * long enough that it's cooldown could have been reset ... But if they then
 * use their buffs correctly, as in, rapidly after it's CD completes, then
 * they can get a bit of faith back. It should only ever climb to a
 * baseline. We notice irresponsibility, not responsibility, because
 * buddy-bots are always responsible!"
 *
 * So one buddy keeps one Book:
 *   - the short list, made when it joins a party (or the party changes):
 *     for each buff it can give one ally, the members who might benefit
 *     (Power Infusion and Innervate: those who spend mana; any other: all);
 *   - for each player on it, the long cooldowns it watches (LONG_COOLDOWN
 *     seconds or more; shorter ones are "almost part of their rotation"):
 *     when each came ready, and how many whole lengths it has sat ready;
 *   - faith per player and buff: STEP to the power of the uses lost, one
 *     lost each time a cooldown sits ready for its own length, one given
 *     back (never past 1, the baseline) when one is used within SOON
 *     seconds of coming back;
 *   - a player with a long cooldown ready and not yet held a whole length
 *     is saving it for a burn, and one who used one within JUST seconds is
 *     burning: either way their worth to the buff counts PLAYER_BURN times
 *     (a player's burn is the one the player sees), and while they save,
 *     the buddy holds the buff for them if they are still its best target.
 * Making the list again (the party disbands, the player or the buddy
 * leaves, the player logs out and back in) starts every player's faith
 * at the baseline: the agent's call, the easier of the owner's two.
 * Buddies are never written in it: they always use what is ready.
 * The numbers are the agent's calls (2026-11-06), to be judged in game.
 */

#ifndef MOD_BUDDIES_FAITH_H
#define MOD_BUDDIES_FAITH_H

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

namespace BuddyFaith
{
    // {{{ the numbers
    //   LONG_COOLDOWN  seconds: a player's cooldown this long or longer is
    //                  watched (the owner: "2+ minute cooldowns. Maybe 1.5
    //                  minutes"; 90 chosen 2026-10-30, as the fight state's)
    //   STEP           faith kept for each use lost (0.8: two lost uses
    //                  bring a player's burn, x1.25, below a buddy's plain worth)
    //   SOON           seconds after coming back within which a use earns a
    //                  step of faith back ("rapidly after it's CD completes")
    //   JUST           seconds after a use that a player counts as burning
    //                  (open question 1: "just jumped" looks this far back)
    //   PLAYER_BURN    a player saving or burning counts this many times
    //                  their worth ("more satisfying than seeing it go to a bot")
    //   HOLD           the buff's lean while held for a player's burn
    constexpr double LONG_COOLDOWN = 90.0;
    constexpr double STEP          =  0.8;
    constexpr double SOON          = 15.0;
    constexpr double JUST          = 10.0;
    constexpr double PLAYER_BURN   =  1.25;
    constexpr double HOLD          =  0.05;   // the lean of a buff held for a player's burn (the leans' "not now")
    // }}}

    // {{{ ForManaOnly
    // The chosen-ally buffs whose gift only those who spend mana can use
    // (cast haste and cheaper spells; mana itself), by name in lower case as
    // the generated tables name them. Any other buff might help anyone.
    inline bool ForManaOnly(std::string const& buff)
    {
        return buff == "power infusion" || buff == "innervate";
    }
    // }}}

    // {{{ Joiner
    // One member as the list is made: its id, whether it is a player (not a
    // buddy, stand-in or pet), and whether it spends mana.
    struct Joiner { uint64_t id; bool player; bool mana; };
    // }}}

    // {{{ Watch
    // One long cooldown of one player, as last seen: ready (and since when),
    // and the whole lengths of it already counted as lost.
    struct Watch { bool ready = false; double since = 0, length = 0; int counted = 0; };
    // }}}

    // {{{ Book
    struct Book
    {
        std::map<std::string, std::set<uint64_t>>               listed;   // buff -> who might benefit
        std::set<uint64_t>                                      players;  // who are players
        std::map<std::pair<uint64_t, std::string>, int>         lost;     // (player, buff) -> uses lost
        std::map<std::pair<uint64_t, std::string>, Watch>       watching; // (player, cooldown) -> as last seen
        std::map<uint64_t, double>                              usedAt;   // player -> its last long cooldown's use

        // {{{ Make
        // The short list, made on joining or when the party changes: for
        // each buff the buddy can give one ally, who might benefit; and the
        // faith in every player started again at the baseline.
        void Make(std::vector<std::string> const& buffs, std::vector<Joiner> const& party)
        {
            listed.clear(); players.clear(); lost.clear(); watching.clear(); usedAt.clear();
            for (Joiner const& j : party)
            {
                if (j.player) players.insert(j.id);
                for (std::string const& b : buffs)
                    if (j.mana || !ForManaOnly(b)) listed[b].insert(j.id);
            }
        }
        // }}}

        // {{{ Listed
        // Whether a member might benefit from a buff. A buff with no list
        // (none made, or not one this buddy gives) leaves everyone in.
        bool Listed(uint64_t who, std::string const& buff) const
        {
            auto it = listed.find(buff);
            return it == listed.end() || it->second.count(who) > 0;
        }
        // }}}

        // {{{ Lose, Regain
        // A use lost or earned back, for every buff the player is listed for.
        void Lose(uint64_t who, int uses)
        {
            for (auto const& [buff, members] : listed)
                if (members.count(who)) lost[{ who, buff }] += uses;
        }
        void Regain(uint64_t who)
        {
            for (auto const& [buff, members] : listed)
                if (members.count(who))
                {
                    int& n = lost[{ who, buff }];
                    n = std::max(0, n - 1);
                }
        }
        // }}}

        // {{{ Saw
        // One of a player's cooldowns as the server sees it now: its name,
        // its whole length and the seconds until it is ready (0: ready).
        // Ready: each whole length it has sat ready loses a use. Taken
        // (ready before, not now): a use within SOON of coming back earns a
        // step back, and the player is burning from now. Short cooldowns,
        // and anyone not a player, are not watched.
        void Saw(uint64_t who, std::string const& cooldown, double length, double readyIn, double now)
        {
            if (!players.count(who) || length < LONG_COOLDOWN) return;
            Watch& w = watching[{ who, cooldown }];
            w.length = length;
            if (readyIn <= 0.0)
            {
                if (!w.ready) { w.ready = true; w.since = now; w.counted = 0; }
                int held = int(std::floor((now - w.since) / length));
                if (held > w.counted) { Lose(who, held - w.counted); w.counted = held; }
                return;
            }
            if (w.ready)
            {
                if (now - w.since <= SOON) Regain(who);
                usedAt[who] = now;
                w.ready = false;
            }
        }
        // }}}

        // {{{ Faith
        // STEP to the power of the uses lost, for this player and buff: 1
        // (the baseline) for a buddy, for anyone with none lost.
        double Faith(uint64_t who, std::string const& buff) const
        {
            auto it = lost.find({ who, buff });
            return it == lost.end() ? 1.0 : std::pow(STEP, it->second);
        }
        // }}}

        // {{{ Saving, Burning
        // Saving: a player with a long cooldown ready that hasn't yet sat
        // ready a whole length (past that it is a use lost, not a save).
        // Burning: a player who used a long cooldown within JUST seconds.
        bool Saving(uint64_t who, double now) const
        {
            if (!players.count(who)) return false;
            for (auto const& [key, w] : watching)
                if (key.first == who && w.ready && now - w.since < w.length) return true;
            return false;
        }
        bool Burning(uint64_t who, double now) const
        {
            auto it = usedAt.find(who);
            return players.count(who) && it != usedAt.end() && now - it->second <= JUST;
        }
        // }}}

        // {{{ Weight
        // What a member's worth to a buff is multiplied by when the buddy
        // chooses whom it goes on: 0 off the list; for a player its faith,
        // times PLAYER_BURN while saving or burning; 1 for anyone else.
        double Weight(uint64_t who, std::string const& buff, double now) const
        {
            if (!Listed(who, buff)) return 0.0;
            if (!players.count(who)) return 1.0;
            return Faith(who, buff) * (Saving(who, now) || Burning(who, now) ? PLAYER_BURN : 1.0);
        }
        // }}}
    };
    // }}}
}

#endif
