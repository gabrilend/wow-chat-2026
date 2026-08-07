# 917 - Ask the Bots in Plain Text

## Status
- Created: 2026-08-01
- Phase: 9 (sibling of 916 — shares its cluster and bindings)
- Priority: Medium
- Depends on: 916 family (Ollama client, worker pool, ALE bindings)

## Overview

An AI orchestration layer for bots in a video game. The player types what
they want in ordinary language. The layer reads the game state, writes
the bot commands, and issues them.

The player never learns a command language.

> the AI should write those commands. The player should just ask.

That is the whole design. mod-playerbots already responds to a large
chat-command vocabulary — large enough that the Multibot and Unbot
addons exist to help people drive it. Learning it is work. Asking isn't.

## What It Is Not

- **Not a narrator.** The project has narrators — the wandering one, the
  audience-facing one, the lore generator. This isn't them, and nothing
  here replaces them.
- **Not an agent with its own goals.** It carries requests and reports
  back. It doesn't decide what the bot AI would have decided faster.
- **Not a restricted subset.** Everything the player can do, including
  logging a character out, is available. Either the player does it, or
  the system they built with the AI does it. There is no third category
  and no forbidden list — you don't restrict yourself.

## The Action Surface Already Exists

From the playerbot docs: *"Playerbots are programmed to respond to chat
commands."* Whisper for one bot, party or raid chat for several. Setup
commands are dot-commands from the console.

So the layer writes chat commands and dot-commands — the same ones a
player would type. Two things fall out of that:

- **Parity is free.** Every command it can write is one a player could
  have written. Nothing extends the game.
- **No new control path.** Nothing needs building into the bots. The
  door is already there; this is a different way of knocking.

## Flow

```
player types:  "have everyone repair and meet me at the bridge"
      │
      ▼
  state as text        who's out, where, what they're doing,
      │                IDs resolved to names          (917a)
      ▼
  the cluster          writes the commands            (917c)
      │
      ▼
  issued as bot chat / dot-commands
      │
      ▼
  reply in text        what it did, in a sentence     (917b)
```

## Sub-Issues

- **917a — What it can see.** Bot and world state rendered as text, with
  entry IDs joined against the world database so names are names. The
  model reads this; it looks nothing else up.

- **917b — The text channel.** Where the player types and where answers
  come back. In-game, minimal.

- **917c — Writing the commands.** Request plus state to a list of
  commands. Validated against the real vocabulary before anything is
  issued. Reports what it did, including when it did nothing.

- **917d — What it keeps doing.** A request doesn't end when the sentence
  does. Standing instructions persist until changed, and the set of them
  is the system the player and the AI build up together over time.

## Open Questions

- Where does the player type — a whisper to a named bot, a slash command,
  a chat channel, or a frame in an addon? In-game is assumed; which
  in-game surface is not decided.
- Does the layer act on one bot at a time, on a party, or on everyone the
  player owns? "Everyone" is what people will say first.
- What happens when a request is ambiguous — guess, or ask back? Asking
  back costs a round trip and is almost certainly right.
- Does it need to see chat, or only state? A bot saying something is a
  fact about the world, and mod-soren-chat is about to make bots talk.
- How much history does a request carry? "Now have her do it too" needs
  the previous exchange; keeping everything is a context-window problem.

## Related

- [916 - mod-soren-chat](916-mod-soren-chat.md) — the cluster, the Ollama
  client, the effil workers, and the ALE bindings into playerbots. This
  is a second consumer of all of it, driven by a person instead of by
  proximity.
- [607 - Player bot behavior commands](607-player-bot-behavior-commands.md)
  — the in-game command vocabulary; this should not become a second
  unrelated way to tell a bot what to do.
- [910 - Wandering narrator system](910-wandering-narrator-system) and
  [908 - Narrator audience facing](908-narrator-audience-facing) — the
  project's actual narrators.
- `docs/playerbots/Playerbot-Commands.md` — the command surface being
  written to.
- `notes/wow-chat-secretary-2` — the standing house position on what an
  LLM should be handed: levers, not arbitrary reach.

## Notes

The original request named a SoraMech-style dataflow system as the
substrate. Set aside 2026-08-01 — not rejected, just not now.

An earlier and much larger version of this design, built around a
listening player and a narrated feed, is in `issues/declined/` under
1101. It was aimed at the wrong thing; the sensor and command-writing
ideas in it may still be worth mining.
</content>
