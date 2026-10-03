/*
 * buddies_whisper.cpp - a whispered buddy answers in a tongue the whisperer
 * can't read (issue 617a5).
 *
 * For a general audience: buddies have no conversation yet; the
 * language-model chat layer (916/917) will give them one. Until then the
 * owner, 2026-10-02: "they should respond in a language that you don't
 * know. Like... Orcish if you're alliance or something. It should just say
 * something like 'I'm sorry, I am a large language model and I have no idea
 * what you're saying'. This is placeholder behavior for when we build
 * proper LLM systems." So a whisper to a buddy gets that line back, sent in
 * the other faction's language.
 *
 * Why the line arrives scrambled: the server never scrambles chat. A chat
 * message travels as plain text plus a language number (ChatHandler::
 * BuildChatPacket), and the game client turns a language its character
 * doesn't know into nonsense words; that is how an orc's /say reads to a
 * human. The server's own whisper (Player::Whisper) forces every whisper to
 * the universal language ("whispers should always be readable"), so this
 * file builds the whisper packet itself with Orcish or Common in it. Whether
 * the client scrambles a *whisper* the way it scrambles /say is the one
 * thing only the game can show (open question in 617a5).
 *
 * Flow: the whisper hook (called inside the whisperer's own whisper, maybe
 * off the world's thread) only notes "answer this person" in a queue
 * behind a lock; the world's update hook sends the answers after a short
 * typing pause, on the world's thread, where looking players up is safe.
 *   - whisperer is a bot (any bot, buddies included): no answer, so two
 *     bots can never whisper each other in a loop
 *   - whisperer answered within the last ANSWER_GAP_MS: no answer, so a
 *     flood of whispers gets one reply, not a flood back
 *   - otherwise: queued, answered after TYPING_PAUSE_MS
 * Nothing is logged per whisper: whispers are ordinary play.
 */

#include "buddies.h"
#include "Chat.h"
#include "CompanionAccounts.h"
#include "GameTime.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <mutex>
#include <unordered_map>
#include <vector>

static char const* const PLACEHOLDER_ANSWER = "I'm sorry, I am a large language model and I have no idea what you're saying";

static constexpr uint64 ANSWER_GAP_MS   = 10000;   // one answer per whisperer per 10 s
static constexpr uint64 TYPING_PAUSE_MS =  1500;   // the answer follows a beat after the whisper

// The tongue a whisperer can't read, by the whisperer's side (TeamId:
// TEAM_ALLIANCE = 0, TEAM_HORDE = 1). A third side (TEAM_NEUTRAL, 2) has no
// faction language a player lacks, so it is not answered at all.
static Language const UNREADABLE_TONGUE[2] =
{
    LANG_ORCISH,                                    // to the Alliance
    LANG_COMMON,                                    // to the Horde
};

struct PendingAnswer
{
    ObjectGuid buddy;                               // who answers
    ObjectGuid whisperer;                           // who hears it
    uint64     dueMs;                               // game time to send at
};

static std::mutex                             answersLock;
static std::vector<PendingAnswer>             answersDue;       // under answersLock
static std::unordered_map<ObjectGuid, uint64> lastAnswerMs;     // whisperer -> last answer queued, under answersLock

// {{{ buddies_whisper_player
class buddies_whisper_player : public PlayerScript
{
public:
    buddies_whisper_player() : PlayerScript("buddies_whisper_player", { PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT }) { }

    // Called inside the whisperer's whisper; the whisper itself always goes
    // through (true): a buddy still receives it, it just can't follow it.
    bool OnPlayerCanUseChat(Player* whisperer, uint32 type, uint32 /*language*/, std::string& /*msg*/, Player* receiver) override
    {
        // not a whisper (the hook also serves other private chat), buddies
        // off, or the receiver isn't a buddy: nothing to answer
        if (!BuddiesEnabled() || type != CHAT_MSG_WHISPER || !CompanionAccounts::Is(receiver->GetSession()->GetAccountId()))
            return true;

        // a bot whispering (the bot module's own chatter, or a buddy): no
        // answer, so bots never answer each other round and round
        if (whisperer->GetSession()->IsBot())
            return true;

        // a side with no foreign tongue (neutral): no answer
        if (whisperer->GetTeamId() > TEAM_HORDE)
            return true;

        uint64 now = GameTime::GetGameTimeMS().count();
        std::lock_guard<std::mutex> guard(answersLock);
        auto last = lastAnswerMs.find(whisperer->GetGUID());

        // answered this person a moment ago: the flood gets one reply
        if (last != lastAnswerMs.end() && now - last->second < ANSWER_GAP_MS)
            return true;

        lastAnswerMs[whisperer->GetGUID()] = now;
        answersDue.push_back({ receiver->GetGUID(), whisperer->GetGUID(), now + TYPING_PAUSE_MS });
        return true;
    }
};
// }}}

// {{{ buddies_whisper_world
class buddies_whisper_world : public WorldScript
{
public:
    buddies_whisper_world() : WorldScript("buddies_whisper_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 /*diff*/) override
    {
        uint64 now = GameTime::GetGameTimeMS().count();
        std::vector<PendingAnswer> ready;
        {
            std::lock_guard<std::mutex> guard(answersLock);
            // the common case, nothing waiting: done at the cost of a lock
            if (answersDue.empty())
                return;
            for (auto it = answersDue.begin(); it != answersDue.end(); )
            {
                // due: taken out to send; not yet: left for a later tick
                if (it->dueMs <= now)
                {
                    ready.push_back(*it);
                    it = answersDue.erase(it);
                }
                else
                    ++it;
            }
            // forget whisperers whose gap has passed, so the table stays small
            for (auto it = lastAnswerMs.begin(); it != lastAnswerMs.end(); )
                it = (now - it->second >= ANSWER_GAP_MS) ? lastAnswerMs.erase(it) : std::next(it);
        }

        for (PendingAnswer const& answer : ready)
        {
            // either logged out during the pause: the conversation is over,
            // and there is nobody to answer or nobody to hear it
            Player* buddy     = ObjectAccessor::FindPlayer(answer.buddy);
            Player* whisperer = ObjectAccessor::FindPlayer(answer.whisperer);
            if (!buddy || !whisperer)
                continue;

            // the whisper packet built by hand: Player::Whisper would force
            // the universal language and make the line readable
            WorldPacket data;
            ChatHandler::BuildChatPacket(data, CHAT_MSG_WHISPER, UNREADABLE_TONGUE[whisperer->GetTeamId()], buddy, buddy, PLACEHOLDER_ANSWER);
            whisperer->SendDirectMessage(&data);
        }
    }
};
// }}}

// {{{ AddSC_buddies_whisper
void AddSC_buddies_whisper()
{
    new buddies_whisper_player();
    new buddies_whisper_world();
}
// }}}
