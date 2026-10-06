# 173b15 - Social and Chat

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store), chat in the client (not yet an
  issue)
- Priority: Low

## Origin

See 173b (the owner's words, 2026-10-06).

## Current Behavior

Not built. The client has no chat.

## Intended Behavior

The original's Social panel (reference page, *Interface* → *Social*),
built with chat:

- *Chat Bubbles* (`chatBubbles`) and *Party Chat Bubbles*
  (`chatBubblesParty`): speech over heads. Buddies talk often, so this
  matters more here than in the original.
- *Mature Language Filter* (`profanityFilter`), *Disable Spam Filter*
  (`spamFilter`).
- *Guild Member Alert* (`guildMemberNotify`), *Auto Join Guild Recruitment
  Channel* (`guildRecruitmentChannel`).
- *Icons in Chat* (`showChatIcons`), *Remove Chat Hover Delay*
  (`removeChatDelay`), *Click to Focus* (`wholeChatWindowClickable`),
  *Enable Mouse Wheel Scrolling* (`chatMouseScroll`).
- *Chat Style* (`chatStyle`): Classic (`classic`: Enter opens the chat
  box) or IM (`im`: the box is always open).
- *Timestamps* (`showTimestamps`): a time before each line, in a chosen
  format.
- *New Real ID Conversations* (`conversationMode`: new tab or in line):
  not copied, with the Battle.net panel below.

**The Battle.net panel** (pop-up notices about Real ID friends) is not
copied. It is for Blizzard's own friend service, which a private server
doesn't have. Cross-server friends are this project's issue 1007.

## Suggested Implementation Steps

1. With chat.

## Open Questions

None yet.
