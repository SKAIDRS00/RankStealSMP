package me.ranksteal.managers;

import me.ranksteal.RankStealPlugin;
import me.ranksteal.database.DatabaseManager;
import me.ranksteal.engine.SwapEngine;
import me.ranksteal.models.PlayerData;
import org.bukkit.entity.Player;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Level;

public class RankManager {

    private final RankStealPlugin plugin;
    private final DatabaseManager db;
    private final SwapEngine swapEngine;

    private final Map<UUID, PlayerData> cache = new ConcurrentHashMap<>();

    public RankManager(RankStealPlugin plugin, DatabaseManager db) {
        this.plugin = plugin;
        this.db = db;
        this.swapEngine = new SwapEngine(plugin, this, db);
    }

    public void loadPlayer(Player player) {
        UUID uuid = player.getUniqueId();
        db.getPlayerData(uuid).thenAccept(data -> {
            if (data == null) {
                registerNewPlayer(player);
            } else {
                data.setUsername(player.getName());
                data.setLastSeen(System.currentTimeMillis());
                cache.put(uuid, data);
                db.savePlayerData(data);
                plugin.getServer().getScheduler().runTask(plugin, () -> {
    plugin.getScoreboardManager().show(player);
    plugin.getTabManager().updatePlayer(player);
    plugin.getTabManager().updateHeader(player);
});
        }).exceptionally(ex -> {
            plugin.getLogger().log(Level.SEVERE, "Failed to load player " + player.getName(), ex);
            return null;
        });
    }

    private void registerNewPlayer(Player player) {
        db.getNextRankNumber().thenAccept(nextRank -> {
            PlayerData data = new PlayerData(
                    player.getUniqueId(),
                    player.getName(),
                    nextRank,
                    0,
                    0,
                    System.currentTimeMillis()
            );
            cache.put(player.getUniqueId(), data);
            db.savePlayerData(data).thenRun(() -> {
                plugin.getServer().getScheduler().runTask(plugin, () -> {
                    plugin.getScoreboardManager().show(player);
                    plugin.getTabManager().updatePlayer(player);
                    broadcastNewPlayer(player, nextRank);
                });
            });
        });
    }

    private void broadcastNewPlayer(Player player, int rank) {
        String msg = plugin.getConfig().getString("messages.new-player-join",
                "<gradient:#00FF88:#00BFFF>✦ {player} joined! Rank: #{rank}</gradient>");
        String formatted = msg
                .replace("{player}", player.getName())
                .replace("{rank}", String.valueOf(rank));
        plugin.getServer().broadcast(plugin.getRankManager().mini(formatted));
    }

    public void unloadPlayer(UUID uuid) {
        PlayerData data = cache.remove(uuid);
        if (data != null) {
            data.setLastSeen(System.currentTimeMillis());
            db.savePlayerData(data);
        }
    }

    public void processKill(Player killer, Player victim) {
        swapEngine.processKill(killer, victim);
    }

    public PlayerData getCached(UUID uuid) {
        return cache.get(uuid);
    }

    public void putCache(PlayerData data) {
        cache.put(data.getUuid(), data);
    }

    public net.kyori.adventure.text.Component mini(String miniMessage) {
        return net.kyori.adventure.text.minimessage.MiniMessage.miniMessage().deserialize(miniMessage);
    }

    public String getRankPrefix(int rank) {
        var top3 = plugin.getConfig().getConfigurationSection("rank.top3-prefixes");
        if (top3 != null && top3.contains(String.valueOf(rank))) {
            return top3.getString(String.valueOf(rank), "");
        }
        return plugin.getConfig().getString("rank.prefix-format", "<gradient:#FFD700:#FFA500>[#{rank}]</gradient> ")
                .replace("{rank}", String.valueOf(rank));
    }

    public SwapEngine getSwapEngine() {
        return swapEngine;
    }
}

