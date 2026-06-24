package me.ranksteal.managers;

import me.ranksteal.RankStealPlugin;
import me.ranksteal.models.PlayerData;
import net.kyori.adventure.text.minimessage.MiniMessage;
import org.bukkit.Bukkit;
import org.bukkit.entity.Player;
import org.bukkit.scheduler.BukkitTask;
import org.bukkit.scoreboard.*;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public class ScoreboardManager {

    private final RankStealPlugin plugin;
    private final MiniMessage mm = MiniMessage.miniMessage();
    private final Map<UUID, Scoreboard> boards = new HashMap<>();
    private BukkitTask task;

    public ScoreboardManager(RankStealPlugin plugin) {
        this.plugin = plugin;
        startUpdater();
    }

    private void startUpdater() {
        int interval = plugin.getConfig().getInt("scoreboard.update-interval", 20);
        task = Bukkit.getScheduler().runTaskTimer(plugin, this::updateAll, interval, interval);
    }

    public void show(Player player) {
        if (!plugin.getConfig().getBoolean("scoreboard.enabled", true)) return;

        org.bukkit.scoreboard.ScoreboardManager manager = Bukkit.getScoreboardManager();
        Scoreboard board = manager.getNewScoreboard();
        Objective obj = board.registerNewObjective("ranksteal", Criteria.DUMMY,
                mm.deserialize(plugin.getConfig().getString("scoreboard.title",
                        "<gradient:#FFD700:#FF4500><bold>✦ RANK STEAL SMP ✦</bold></gradient>")));
        obj.setDisplaySlot(DisplaySlot.SIDEBAR);

        boards.put(player.getUniqueId(), board);
        player.setScoreboard(board);
        update(player, obj);
    }

    public void update(Player player, Objective obj) {
        PlayerData data = plugin.getRankManager().getCached(player.getUniqueId());
        if (data == null) return;

        int online = Bukkit.getOnlinePlayers().size();

        setLine(obj, 15, " ");
        setLine(obj, 14, "§e§lYour Rank");
        setLine(obj, 13, "§f  #" + data.getRankNumber());
        setLine(obj, 12, " §");
        setLine(obj, 11, "§e§lStats");
        setLine(obj, 10, "§f  Kills: §a" + data.getKills());
        setLine(obj,  9, "§f  Deaths: §c" + data.getDeaths());
        setLine(obj,  8, "§f  K/D: §b" + data.getKDR());
        setLine(obj,  7, " §§");
        setLine(obj,  6, "§e§lServer");
        setLine(obj,  5, "§f  Online: §a" + online);
        setLine(obj,  4, " §§§");
        setLine(obj,  3, "§7play.yourserver.net");
    }

    private void setLine(Objective obj, int score, String text) {
        Score s = obj.getScore(text);
        s.setScore(score);
    }

    public void updateAll() {
        for (Player player : Bukkit.getOnlinePlayers()) {
            Scoreboard board = boards.get(player.getUniqueId());
            if (board == null) continue;
            Objective obj = board.getObjective("ranksteal");
            if (obj == null) continue;
            update(player, obj);
        }
    }

    public void remove(Player player) {
        boards.remove(player.getUniqueId());
        player.setScoreboard(Bukkit.getScoreboardManager().getMainScoreboard());
    }

    public void removeAll() {
        for (Player player : Bukkit.getOnlinePlayers()) {
            remove(player);
        }
        if (task != null) task.cancel();
    }

    public void reload() {
        if (task != null) task.cancel();
        boards.clear();
        for (Player player : Bukkit.getOnlinePlayers()) {
            show(player);
        }
        startUpdater();
    }
}

