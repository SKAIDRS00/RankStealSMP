package me.ranksteal.engine;

import me.ranksteal.RankStealPlugin;
import me.ranksteal.database.DatabaseManager;
import me.ranksteal.managers.RankManager;
import me.ranksteal.models.PlayerData;
import net.kyori.adventure.text.minimessage.MiniMessage;
import net.kyori.adventure.title.Title;
import org.bukkit.Sound;
import org.bukkit.entity.Player;

import java.time.Duration;
import java.util.logging.Level;

public class SwapEngine {

    private final RankStealPlugin plugin;
    private final RankManager rankManager;
    private final DatabaseManager db;
    private final MiniMessage mm = MiniMessage.miniMessage();

    public SwapEngine(RankStealPlugin plugin, RankManager rankManager, DatabaseManager db) {
        this.plugin = plugin;
        this.rankManager = rankManager;
        this.db = db;
    }

    public void processKill(Player killer, Player victim) {
        PlayerData killerData = rankManager.getCached(killer.getUniqueId());
        PlayerData victimData = rankManager.getCached(victim.getUniqueId());

        if (killerData == null || victimData == null) return;

        int killerRank = killerData.getRankNumber();
        int victimRank = victimData.getRankNumber();

        if (killerRank == victimRank) return;
        if (killerRank <= victimRank) return;

        int stolenRank = victimRank;

        killerData.setRankNumber(victimRank);
        victimData.setRankNumber(killerRank);
        killerData.incrementKills();
        victimData.incrementDeaths();

        db.swapRanks(killerData, victimData).thenRun(() -> {
            db.savePlayerData(killerData);
            db.savePlayerData(victimData);
        }).exceptionally(ex -> {
            plugin.getLogger().log(Level.SEVERE, "Swap failed — rolling back cache", ex);
            killerData.setRankNumber(killerRank);
            victimData.setRankNumber(victimRank);
            return null;
        });

        plugin.getServer().getScheduler().runTask(plugin, () -> {
            notifyKiller(killer, killerData, killerRank, stolenRank, victim.getName());
            notifyVictim(victim, victimData, killerRank, killer.getName());
            plugin.getScoreboardManager().updateAll();
            plugin.getTabManager().updatePlayer(killer);
            plugin.getTabManager().updatePlayer(victim);
        });
    }

    private void notifyKiller(Player killer, PlayerData data, int oldRank, int stolenRank, String victimName) {
        String msg = plugin.getConfig().getString("messages.rank-stolen-attacker",
                "<gradient:#FF4500:#FFD700>⚔ You stole <white>#{stolen_rank}</white> from <red>{victim}</red>!</gradient>")
                .replace("{stolen_rank}", String.valueOf(stolenRank))
                .replace("{victim}", victimName)
                .replace("{old_rank}", String.valueOf(oldRank))
                .replace("{new_rank}", String.valueOf(data.getRankNumber()));
        killer.sendMessage(mm.deserialize(msg));

        if (plugin.getConfig().getBoolean("actionbar.enabled", true)) {
            String ab = plugin.getConfig().getString("actionbar.kill-message",
                    "<gradient:#FF4500:#FFD700>⚔ You stole rank #{stolen_rank} from {victim}!</gradient>")
                    .replace("{stolen_rank}", String.valueOf(stolenRank))
                    .replace("{victim}", victimName);
            killer.sendActionBar(mm.deserialize(ab));
        }

        Title title = Title.title(
                mm.deserialize("<gradient:#FFD700:#FF4500><bold>RANK STOLEN!</bold></gradient>"),
                mm.deserialize("<gray>#" + oldRank + " <white>→</white> <yellow>#" + data.getRankNumber() + "</yellow></gray>"),
                Title.Times.times(Duration.ofMillis(200), Duration.ofMillis(2500), Duration.ofMillis(500))
        );
        killer.showTitle(title);

        if (plugin.getConfig().getBoolean("sounds.rank-steal.enabled", true)) {
            String soundName = plugin.getConfig().getString("sounds.rank-steal.sound", "ENTITY_PLAYER_LEVELUP");
            float volume = (float) plugin.getConfig().getDouble("sounds.rank-steal.volume", 1.0);
            float pitch  = (float) plugin.getConfig().getDouble("sounds.rank-steal.pitch", 1.2);
            try {
                killer.playSound(killer.getLocation(), Sound.valueOf(soundName), volume, pitch);
            } catch (IllegalArgumentException ignored) {}
        }
    }

    private void notifyVictim(Player victim, PlayerData data, int newRank, String killerName) {
        String msg = plugin.getConfig().getString("messages.rank-stolen-victim",
                "<gradient:#FF0000:#FF6347>💀 <white>{killer}</white> stole your rank! You dropped to <white>#{new_rank}</white></gradient>")
                .replace("{killer}", killerName)
                .replace("{new_rank}", String.valueOf(data.getRankNumber()));
        victim.sendMessage(mm.deserialize(msg));

        Title title = Title.title(
                mm.deserialize("<red><bold>RANK LOST!</bold></red>"),
                mm.deserialize("<gray>Dropped to <white>#" + data.getRankNumber() + "</white></gray>"),
                Title.Times.times(Duration.ofMillis(200), Duration.ofMillis(2500), Duration.ofMillis(500))
        );
        victim.showTitle(title);
    }
}

