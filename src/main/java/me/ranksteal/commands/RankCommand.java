package me.ranksteal.commands;

import me.ranksteal.RankStealPlugin;
import me.ranksteal.models.PlayerData;
import net.kyori.adventure.text.minimessage.MiniMessage;
import org.bukkit.Bukkit;
import org.bukkit.command.Command;
import org.bukkit.command.CommandExecutor;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.Player;
import org.jetbrains.annotations.NotNull;

public class RankCommand implements CommandExecutor {

    private final RankStealPlugin plugin;
    private final MiniMessage mm = MiniMessage.miniMessage();

    public RankCommand(RankStealPlugin plugin) {
        this.plugin = plugin;
    }

    @Override
    public boolean onCommand(@NotNull CommandSender sender, @NotNull Command command,
                             @NotNull String label, @NotNull String[] args) {
        if (!sender.hasPermission("ranksteal.rank")) {
            sender.sendMessage(mm.deserialize(plugin.getConfig().getString("messages.no-permission", "<red>No permission.</red>")));
            return true;
        }

        if (args.length == 0) {
            if (!(sender instanceof Player player)) {
                sender.sendMessage(mm.deserialize("<red>Console must specify a player: /rank <player></red>"));
                return true;
            }
            showRank(sender, plugin.getRankManager().getCached(player.getUniqueId()), player.getName());
        } else {
            String targetName = args[0];
            Player online = Bukkit.getPlayerExact(targetName);
            if (online != null) {
                PlayerData data = plugin.getRankManager().getCached(online.getUniqueId());
                showRank(sender, data, online.getName());
            } else {
                plugin.getDatabaseManager().getPlayerByName(targetName).thenAccept(data -> {
                    plugin.getServer().getScheduler().runTask(plugin, () -> showRank(sender, data, targetName));
                });
            }
        }
        return true;
    }

    private void showRank(CommandSender sender, PlayerData data, String name) {
        if (data == null) {
            sender.sendMessage(mm.deserialize(
                    plugin.getConfig().getString("messages.player-not-found", "<red>Player not found.</red>")));
            return;
        }

        String prefix = plugin.getConfig().getString("messages.prefix", "<gradient:#FFD700:#FFA500><bold>[RS]</bold></gradient> ");
        String template = plugin.getConfig().getString("messages.rank-info",
                "<yellow>Rank: <white>#{rank}</white> | Kills: <white>{kills}</white> | Deaths: <white>{deaths}</white></yellow>");

        String msg = prefix + "<white>" + name + "</white> — " + template
                .replace("{rank}", String.valueOf(data.getRankNumber()))
                .replace("{kills}", String.valueOf(data.getKills()))
                .replace("{deaths}", String.valueOf(data.getDeaths()))
                .replace("{kdr}", String.valueOf(data.getKDR()));

        sender.sendMessage(mm.deserialize(msg));
    }
}

