# Refused Channels Patch (B038)

## Overview

A profile can list built-in chat channels nobody may join. On basic
(issue 155x) the list is General, Trade, LocalDefense, WorldDefense,
GuildRecruitment and LookingForGroup, "to keep news from spreading". A refused join is silent: no error, the channel
is not there. Custom channels (`/join anything`) are never refused. With no
list set (every other profile) nothing changes.

No script hook sees every join: a client's request, the server's move
between zone channels on a zone change (`Player::UpdateLocalChannels`), and
the bot module's own joins (`PlayerbotHolder`, `PlayerbotMgr.cpp`) all end
in `Channel::JoinChannel`, so the check sits at its top.

## Files to Modify

### 1. `src/server/game/Chat/Channels/Channel.cpp`

After `#include "AccountMgr.h"`, add:

```cpp
#include "Config.h"
#include <set>
#include <sstream>
```

As the first lines of `void Channel::JoinChannel(Player* player, std::string const& pass)`:

```cpp
    {
        static std::set<uint32> const refused = []
        {
            std::set<uint32> ids;
            std::istringstream in(sConfigMgr->GetOption<std::string>("Basic.RefusedChannels", "", false));
            for (uint32 id; in >> id; )
                ids.insert(id);
            return ids;
        }();
        if (IsConstant() && refused.count(GetChannelId()))
            return;
    }
```

`GetChannelId()` is the client's channel number (ChatChannels.dbc); custom
channels have none (`IsConstant()` false), so they are never refused.

## Usage

In `worldserver.conf` (basic's config patch C031 writes it):

```
Basic.RefusedChannels = "1 2 22 23 25 26"
```

Numbers: 1 General, 2 Trade, 22 LocalDefense, 23 WorldDefense,
25 GuildRecruitment, 26 LookingForGroup. Read once, at the first join after
the server starts; a change needs a restart. `basic_rules.cpp` logs the
list at startup.

## Build Instructions

Applied by `patches/B038-refused-channels.sh` for the profiles that list
B038 in `patches/patches.sh` (basic), then `scripts/compile`.
`scripts/test-source-patches` checks the apply/revert round trip;
`scripts/test-patched-syntax` compiles the patched file.
