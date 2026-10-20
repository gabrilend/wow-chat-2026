
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

static constexpr uint64 ANSWER_GAP_MS   = 10000;
static constexpr uint64 TYPING_PAUSE_MS =  1500;

static Language const UNREADABLE_TONGUE[2] =
{
    LANG_ORCISH,
    LANG_COMMON,
};

struct PendingAnswer
{
    ObjectGuid buddy;
    ObjectGuid whisperer;
    uint64     dueMs;
};

static std::mutex                             answersLock;
static std::vector<PendingAnswer>             answersDue;
static std::unordered_map<ObjectGuid, uint64> lastAnswerMs;

class buddies_whisper_player : public PlayerScript
{
public:
    buddies_whisper_player() : PlayerScript("buddies_whisper_player", { PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT }) { }

    bool OnPlayerCanUseChat(Player* whisperer, uint32 type, uint32 , std::string& , Player* receiver) override
    {
        if (!BuddiesEnabled() || type != CHAT_MSG_WHISPER || !CompanionAccounts::Is(receiver->GetSession()->GetAccountId()))
            return true;

        if (whisperer->GetSession()->IsHeadless())
            return true;

        if (whisperer->GetTeamId() > TEAM_HORDE)
            return true;

        uint64 now = GameTime::GetGameTimeMS().count();
        std::lock_guard<std::mutex> guard(answersLock);
        auto last = lastAnswerMs.find(whisperer->GetGUID());

        if (last != lastAnswerMs.end() && now - last->second < ANSWER_GAP_MS)
            return true;

        lastAnswerMs[whisperer->GetGUID()] = now;
        answersDue.push_back({ receiver->GetGUID(), whisperer->GetGUID(), now + TYPING_PAUSE_MS });
        return true;
    }
};

class buddies_whisper_world : public WorldScript
{
public:
    buddies_whisper_world() : WorldScript("buddies_whisper_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 ) override
    {
        uint64 now = GameTime::GetGameTimeMS().count();
        std::vector<PendingAnswer> ready;
        {
            std::lock_guard<std::mutex> guard(answersLock);
            if (answersDue.empty())
                return;
            for (auto it = answersDue.begin(); it != answersDue.end(); )
            {
                if (it->dueMs <= now)
                {
                    ready.push_back(*it);
                    it = answersDue.erase(it);
                }
                else
                    ++it;
            }
            for (auto it = lastAnswerMs.begin(); it != lastAnswerMs.end(); )
                it = (now - it->second >= ANSWER_GAP_MS) ? lastAnswerMs.erase(it) : std::next(it);
        }

        for (PendingAnswer const& answer : ready)
        {
            Player* buddy     = ObjectAccessor::FindPlayer(answer.buddy);
            Player* whisperer = ObjectAccessor::FindPlayer(answer.whisperer);
            if (!buddy || !whisperer)
                continue;

            WorldPacket data;
            ChatHandler::BuildChatPacket(data, CHAT_MSG_WHISPER, UNREADABLE_TONGUE[whisperer->GetTeamId()], buddy, buddy, PLACEHOLDER_ANSWER);
            whisperer->SendDirectMessage(&data);
        }
    }
};

void AddSC_buddies_whisper()
{
    new buddies_whisper_player();
    new buddies_whisper_world();
}
