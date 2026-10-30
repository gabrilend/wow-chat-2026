/*
 * buddies_map_stream.cpp - every character's position, live, for the map
 * page (issue 617e16a).
 *
 * For a general audience: the owner wants a web page that shows where
 * everyone in the game is (the fish-school sandbox, docs/HTML/fish-sandbox.html).
 * A page can't read the server's memory, so the server answers it: once a
 * second, on the world's own thread, it writes down where every character
 * in the world stands (as JSON text), and a small listener on a thread of
 * its own hands that text to anyone on this computer who asks for
 * http://127.0.0.1:<port>/positions. Two halves, joined by one string
 * behind a lock:
 *   the snapshot - the world's thread, every SNAPSHOT_MS: the players (the
 *                  server's own list of them), each one's number, name,
 *                  kind (a buddy, by the roster; another bot, by its
 *                  session having no client; else a person's), a buddy's
 *                  owner, map, zone, sub-zone, position, facing, and
 *                  whether it fights or is dead;
 *   the listener - Boost.Asio on its own thread: each connection is read
 *                  up to the end of its request and answered with the
 *                  latest snapshot, then closed. Bound to 127.0.0.1 only:
 *                  nothing off this computer can reach it. The answer
 *                  carries "Access-Control-Allow-Origin: *" so a page
 *                  opened from its file may read it.
 * The port is Buddies.MapStream.Port in worldserver.conf (DEFAULT_PORT when
 * absent; 0 turns the stream off). Shut down with the world.
 */

#include "buddies.h"
#include "buddies_roam.h"
#include "Config.h"
#include "GameTime.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include <boost/asio.hpp>
#include <atomic>
#include <memory>
#include <mutex>
#include <sstream>
#include <string>
#include <thread>
#include <unordered_map>

// {{{ tuning
static constexpr uint32 SNAPSHOT_MS   = 1000;      // how often the positions are written down
static constexpr int32  DEFAULT_PORT  = 8097;      // Buddies.MapStream.Port when the line is absent
static constexpr size_t REQUEST_LIMIT = 8192;      // bytes of a request read before answering anyway
// }}}

// {{{ the snapshot, shared
static std::mutex  sSnapshotLock;
static std::string sSnapshot = "{\"time\":0,\"characters\":[]}";
// }}}

// {{{ Snapshot
// Called on the world's thread. Names are letters only in this game, so
// they need no escaping beyond the quotes round them.
static std::string Snapshot()
{
    std::unordered_map<uint32, uint32> ownerOf;
    for (auto const& [buddy, owner] : BuddyRosterPairs())
        ownerOf[buddy] = owner;
    std::ostringstream out;
    out.setf(std::ios::fixed);
    out.precision(1);
    out << "{\"time\":" << GameTime::GetGameTime().count() << ",\"characters\":[";
    bool first = true;
    std::shared_lock<std::shared_mutex> lock(*HashMapHolder<Player>::GetLock());
    for (auto const& [guid, p] : ObjectAccessor::GetPlayers())
    {
        if (!p || !p->IsInWorld())
            continue;
        uint32 low = p->GetGUID().GetCounter();
        auto owned = ownerOf.find(low);
        // each kind, and what the page draws: a buddy in its owner's
        // colour, another bot grey, a person's character white
        char const* kind = owned != ownerOf.end() ? "buddy" : (p->GetSession() && p->GetSession()->IsHeadless() ? "bot" : "player");
        if (!first)
            out << ",";
        first = false;
        out << "{\"g\":" << low << ",\"n\":\"" << p->GetName() << "\",\"k\":\"" << kind << "\",\"o\":"
            << (owned != ownerOf.end() ? owned->second : 0) << ",\"m\":" << p->GetMapId() << ",\"z\":" << p->GetZoneId()
            << ",\"a\":" << p->GetAreaId() << ",\"x\":" << p->GetPositionX() << ",\"y\":" << p->GetPositionY()
            << ",\"r\":" << p->GetOrientation() << ",\"c\":" << (p->IsInCombat() ? 1 : 0) << ",\"d\":" << (p->IsAlive() ? 0 : 1) << "}";
    }
    out << "]}";
    return out.str();
}
// }}}

// {{{ the listener
// One connection at a time is plenty for a page asking once a second: each
// is read up to its blank line (or REQUEST_LIMIT), answered, closed.
class MapStreamListener
{
public:
    explicit MapStreamListener(uint16 port)
        : _acceptor(_io, boost::asio::ip::tcp::endpoint(boost::asio::ip::make_address("127.0.0.1"), port))
    {
        Accept();
        _thread = std::thread([this] { _io.run(); });
    }

    ~MapStreamListener()
    {
        _io.stop();
        if (_thread.joinable())
            _thread.join();
    }

private:
    void Accept()
    {
        auto socket = std::make_shared<boost::asio::ip::tcp::socket>(_io);
        _acceptor.async_accept(*socket, [this, socket](boost::system::error_code const& ec)
        {
            if (!ec)
                Read(socket);
            Accept();
        });
    }

    void Read(std::shared_ptr<boost::asio::ip::tcp::socket> socket)
    {
        auto buffer = std::make_shared<boost::asio::streambuf>(REQUEST_LIMIT);
        boost::asio::async_read_until(*socket, *buffer, "\r\n\r\n",
            [socket, buffer](boost::system::error_code const& /*ec*/, std::size_t /*n*/)
        {
            std::string first;
            std::istream in(buffer.get());
            std::getline(in, first);
            // each request, and its answer:
            //   GET /positions ... - the latest snapshot, as JSON
            //   anything else      - 404, saying what is served
            bool wanted = first.rfind("GET /positions", 0) == 0;
            std::string body;
            if (wanted)
            {
                std::lock_guard<std::mutex> lock(sSnapshotLock);
                body = sSnapshot;
            }
            else
                body = "the world server's map stream answers GET /positions only (issue 617e16a)\n";
            auto reply = std::make_shared<std::string>(
                std::string(wanted ? "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n" : "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n") +
                "Access-Control-Allow-Origin: *\r\nCache-Control: no-store\r\nConnection: close\r\nContent-Length: " +
                std::to_string(body.size()) + "\r\n\r\n" + body);
            boost::asio::async_write(*socket, boost::asio::buffer(*reply),
                [socket, reply](boost::system::error_code const& /*ec*/, std::size_t /*n*/)
            {
                boost::system::error_code ignored;
                socket->shutdown(boost::asio::ip::tcp::socket::shutdown_both, ignored);
                socket->close(ignored);
            });
        });
    }

    boost::asio::io_context        _io;
    boost::asio::ip::tcp::acceptor _acceptor;
    std::thread                    _thread;
};
static std::unique_ptr<MapStreamListener> sListener;
// }}}

// {{{ buddies_map_stream_world
class buddies_map_stream_world : public WorldScript
{
public:
    buddies_map_stream_world() : WorldScript("buddies_map_stream_world", { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE, WORLDHOOK_ON_SHUTDOWN }) { }

    // The listener starts with the world. Each case, and what it means:
    //   port 0         - the stream is off (said once)
    //   bound          - serving (said once, with the address)
    //   the port taken - not serving, the reason said; the server runs on
    void OnStartup() override
    {
        int32 port = sConfigMgr->GetOption<int32>("Buddies.MapStream.Port", DEFAULT_PORT);
        if (port <= 0 || port > 65535)
        {
            LOG_INFO("module", "mod-buddies: the map stream is off (Buddies.MapStream.Port = {})", port);
            return;
        }
        try
        {
            sListener = std::make_unique<MapStreamListener>(uint16(port));
            LOG_INFO("module", ">> mod-buddies: every character's position served at http://127.0.0.1:{}/positions (issue 617e16a)", port);
        }
        catch (std::exception const& e)
        {
            LOG_ERROR("module", "mod-buddies: the map stream could not listen on 127.0.0.1:{} ({}); the page's live players stay off. "
                "To debug: is another program on that port (ss -ltnp | grep {})? Buddies.MapStream.Port in worldserver.conf moves it.",
                port, e.what(), port);
        }
    }

    void OnUpdate(uint32 diff) override
    {
        if (!sListener)
            return;
        _since += diff;
        if (_since < SNAPSHOT_MS)
            return;
        _since = 0;
        std::string snap = Snapshot();
        std::lock_guard<std::mutex> lock(sSnapshotLock);
        sSnapshot.swap(snap);
    }

    void OnShutdown() override
    {
        sListener.reset();
    }

private:
    uint32 _since = 0;
};
// }}}

// {{{ AddSC_buddies_map_stream
void AddSC_buddies_map_stream()
{
    new buddies_map_stream_world();
}
// }}}
