
#include "buddies_fight_replay.h"
#include "buddies_forward_pass.h"

#include <cmath>
#include <cstdio>
#include <fstream>
#include <sstream>
#include <string>

int main(int argc, char** argv)
{
    if (argc < 2) { std::fprintf(stderr, "replay-fight: which fight? (a file the server wrote, see --help)\n"); return 2; }
    bool leans = argc > 2 && std::string(argv[2]) == "--leans";
    std::ifstream f(argv[1]);
    if (!f) { std::fprintf(stderr, "replay-fight: cannot read %s\n", argv[1]); return 2; }
    std::stringstream text;
    text << f.rdbuf();
    std::string error;
    auto steps = BuddyFightReplay::Read(text.str(), &error);
    if (!error.empty()) std::fprintf(stderr, "replay-fight: %s (the %zu steps before it are replayed)\n", error.c_str(), steps.size());

    int differ = 0;
    BuddyFightReplay::Replay(steps, [&](BuddyFightReplay::Step const& st, BuddyFightState::Memory const& m) {
        BuddyForwardPass::Verdict v = BuddyForwardPass::Step(st.snapshot, m);
        bool same = st.shortfall < 0 || std::fabs(v.shortfall - st.shortfall) <= 1e-6 * std::max(1.0, st.shortfall);
        if (!same) ++differ;
        std::printf("t %8.1f  %s  %5.0f s left%s  short %9.0f%s", st.snapshot.t, v.kind == BuddyPlan::Fight::Boss ? "boss " : "trash",
                    v.left, v.leftKnown ? "" : " (horizon)", v.shortfall, same ? "" : "  (the game said otherwise)");
        if (v.tanks.holder >= 0)
            std::printf("  tank %llu%s", (unsigned long long)st.snapshot.party[v.tanks.holder].id,
                        v.tanks.to >= 0 ? (" then " + std::to_string(st.snapshot.party[v.tanks.to].id) + " in " + std::to_string(int(v.tanks.at)) + " s").c_str() : "");
        std::printf("\n");
        if (leans)
            for (size_t b = 0; b < st.snapshot.party.size(); ++b)
            {
                std::string line;
                for (auto const& [name, lean] : BuddyForwardPass::Leans(st.snapshot, m, int(b), 0.0))
                    if (std::fabs(lean - 1.0) > 1e-3) line += "  " + name + " x" + std::to_string(lean).substr(0, 5);
                if (!line.empty()) std::printf("    member %llu:%s\n", (unsigned long long)st.snapshot.party[b].id, line.c_str());
            }
    });
    std::printf("%zu steps replayed; %d differ from what the game worked out\n", steps.size(), differ);
    return differ == 0 && error.empty() ? 0 : 1;
}
