package me.ranksteal.listeners;

import me.ranksteal.RankStealPlugin;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerQuitEvent;

public class PlayerQuitListener implements Listener {

    private final RankStealPlugin plugin;

    public PlayerQuitListener(RankStealPlugin plugin) {
        this.plugin = plugin;
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void onPlayerQuit(PlayerQuitEvent event) {
        plugin.getRankManager().unloadPlayer(event.getPlayer().getUniqueId());
        plugin.getScoreboardManager().remove(event.getPlayer());
    }
}

