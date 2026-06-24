package me.ranksteal.managers;

import me.ranksteal.RankStealPlugin;
import me.ranksteal.models.PlayerData;
import net.kyori.adventure.text.minimessage.MiniMessage;
import org.bukkit.Bukkit;
import org.bukkit.entity.Player;

public class TabManager {

    private final RankStealPlugin plugin;
    private final MiniMessage mm = MiniMessage.miniMessage();

    public TabManager(RankStealPlugin plugin) {
        this.plugin = plugin;
    }

    public void updatePlayer(Player player) {
        if (!plugin.getConfig().getBoolean("tab.enabled", true)) return;

        PlayerData data = plugin.getRankManager().getCached(player.getUniqueId());
        if (data == null) return;

        String prefix = plugin.getRankManager().getRankPrefix(data.getRankNumber());
        String listName = prefix + "<white>" + player.getName() + "</white>";
        player.playerListName(mm.deserialize(listName));
    }

    public void updateHeader(Player player) {
        int online = Bukkit.getOnlinePlayers().size();
        String header = plugin.getConfig().getString("tab.header", "\n<gradient:#FFD700:#FFA500><bold>✦ RankSteal SMP ✦</bold></gradient>\n")
                .replace("{online}", String.valueOf(online));
        String footer = plugin.getConfig().getString("tab.footer", "\n<gray>Players Online: <white>{online}</white></gray>\n")
                .replace("{online}", String.valueOf(online));
        player.sendPlayerListHeaderAndFooter(mm.deserialize(header), mm.deserialize(footer));
    }

    public void updateAll() {
        for (Player player : Bukkit.getOnlinePlayers()) {
            updatePlayer(player);
            updateHeader(player);
        }
    }

    public void reload() {
        updateAll();
    }
}

