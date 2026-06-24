package me.ranksteal.api;

import me.ranksteal.RankStealPlugin;
import me.ranksteal.models.PlayerData;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

/**
 * Public API for RankStealSMP.
 * Other plugins can use this to read and interact with rank data.
 *
 * Usage:
 *   RankStealAPI api = RankStealAPI.get();
 *   api.getPlayerData(uuid).thenAccept(data -> { ... });
 */
public class RankStealAPI {

    private static RankStealAPI instance;
    private final RankStealPlugin plugin;

    private RankStealAPI(RankStealPlugin plugin) {
        this.plugin = plugin;
    }

    public static void init(RankStealPlugin plugin) {
        instance = new RankStealAPI(plugin);
    }

    public static RankStealAPI get() {
        if (instance == null) throw new IllegalStateException("RankStealSMP is not loaded.");
        return instance;
    }

    /** Get a player's data by UUID (async). Returns null if never joined. */
    public CompletableFuture<PlayerData> getPlayerData(UUID uuid) {
        PlayerData cached = plugin.getRankManager().getCached(uuid);
        if (cached != null) return CompletableFuture.completedFuture(cached);
        return plugin.getDatabaseManager().getPlayerData(uuid);
    }

    /** Get player at a specific rank number (async). */
    public CompletableFuture<PlayerData> getPlayerAtRank(int rank) {
        return plugin.getDatabaseManager().getPlayerByRank(rank);
    }

    /** Get the top N ranked players (async). */
    public CompletableFuture<List<PlayerData>> getTopRanks(int limit) {
        return plugin.getDatabaseManager().getTopRanks(limit, 0);
    }

    /** Get total registered players. */
    public CompletableFuture<Integer> getTotalPlayers() {
        return plugin.getDatabaseManager().getTotalPlayers();
    }

    /** Get rank number for a UUID (cached, or -1 if not loaded). */
    public int getCachedRank(UUID uuid) {
        PlayerData data = plugin.getRankManager().getCached(uuid);
        return data != null ? data.getRankNumber() : -1;
    }
}

