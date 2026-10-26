pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    function hasRealArt(player) {
        const art = player?.trackArtUrl ?? "";
        return art.startsWith("http") || art.endsWith("jpg") || art.endsWith("png");
    }

    function stateRank(player) {
        switch (player.playbackState) {
        case MprisPlaybackState.Playing:
            return 2;
        case MprisPlaybackState.Paused:
            return 1;
        default:
            return 0;
        }
    }

    function pick(players, current) {
        let best = players.includes(current) ? current : null;
        for (let player of players) {
            if (player === best || player.trackArtUrl.length === 0)
                continue;
            if (!best || stateRank(player) > stateRank(best) || (stateRank(player) === stateRank(best) && hasRealArt(player) && !hasRealArt(best)))
                best = player;
        }
        return best;
    }
}
