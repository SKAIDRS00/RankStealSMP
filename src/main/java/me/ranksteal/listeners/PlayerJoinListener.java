package me.ranksteal.listeners;

import me.ranksteal.RankStealPlugin;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;

public class PlayerJoinListener implements Listener {

    private final RankStealPlugin plugin;

    public PlayerJoinListener(RankStealPlugin plugin) {
        this.plugin = plugin;
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void onPlayerJoin(PlayerJoinEvent event) {
        Player player = event.getPlayer();
        plugin.getRankManager().loadPlayer(player);
        plugin.getTabManager().updateHeader(player);
    }
}

