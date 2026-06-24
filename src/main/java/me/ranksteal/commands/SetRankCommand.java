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

public class SetRankCommand implements CommandExecutor {

    private final RankStealPlugin plugin;
    private final MiniMessage mm = MiniMessage.miniMessage();

    public SetRankCommand(RankStealPlugin plugin) {
        this.plugin = plugin;
    }

    @Override
    public boolean onCommand(@NotNull CommandSender sender, @NotNull Command command,
                             @NotNull String label, @NotNull String[] args) {
        if (!sender.hasPermission("ranksteal.admin.setrank")) {
            sender.sendMessage(mm.deserialize(plugin.getConfig().getString("messages.no-permission", "<red>No permission.</red>")));
            return true;
        }

        if (args.length < 2) {
            sender.sendMessage(mm.deserialize("<red>Usage: /setrank <player> <rank></red>"));
            return true;
        }

        String targetName = args[0];
        int targetRank;
        try {
            targetRank = Integer.parseInt(args[1]);
            if (targetRank < 1) throw new NumberFormatException();
        } catch (NumberFormatException e) {
            sender.sendMessage(mm.deserialize("<red>Invalid rank number. Must be a positive integer.</red>"));
            return true;
        }

        plugin.getDatabaseManager().getTotalPlayers().thenAccept(total -> {
            final int maxRank = total;
            if (targetRank > maxRank + 1) {
                plugin.getServer().getScheduler().runTask(plugin, () ->
                        sender.sendMessage(mm.deserialize(
                                plugin.getConfig().getString("messages.setrank-invalid", "<red>Invalid rank number. Must be between 1 and {max}.</red>")
                                        .replace("{max}", String.valueOf(maxRank)))));
                return;
            }

            plugin.getDatabaseManager().getPlayerByRank(targetRank).thenAccept(holder -> {
                String tName = targetName;
                Player online = Bukkit.getPlayerExact(tName);
                PlayerData targetData = online != null
                        ? plugin.getRankManager().getCached(online.getUniqueId())
                        : null;

                if (targetData == null) {
                    plugin.getDatabaseManager().getPlayerByName(tName).thenAccept(data -> {
                        if (data == null) {
                            plugin.getServer().getScheduler().runTask(plugin, () ->
                                    sender.sendMessage(mm.deserialize(
                                            plugin.getConfig().getString("messages.player-not-found", "<red>Player not found.</red>"))));
                            return;
                        }
                        applySetRank(sender, data, holder, targetRank);
                    });
                } else {
                    applySetRank(sender, targetData, holder, targetRank);
                }
            });
        });

        return true;
    }

    private void applySetRank(CommandSender sender, PlayerData target, PlayerData holder, int targetRank) {
        if (holder != null && !holder.getUuid().equals(target.getUuid())) {
            sender.sendMessage(mm.deserialize(
                    plugin.getConfig().getString("messages.setrank-occupied",
                            "<red>Rank #{rank} is already taken by {holder}.</red>")
                            .replace("{rank}", String.valueOf(targetRank))
                            .replace("{holder}", holder.getUsername())));
            return;
        }

        int oldRank = target.getRankNumber();
        target.setRankNumber(targetRank);
        plugin.getRankManager().putCache(target);

        plugin.getDatabaseManager().savePlayerData(target).thenRun(() -> {
            plugin.getServer().getScheduler().runTask(plugin, () -> {
                String msg = plugin.getConfig().getString("messages.setrank-success",
                        "<green>✓ Set <white>{player}</white>'s rank to <white>#{rank}</white>.</green>")
                        .replace("{player}", target.getUsername())
                        .replace("{rank}", String.valueOf(targetRank));
                sender.sendMessage(mm.deserialize(msg));

                Player targetOnline = Bukkit.getPlayer(target.getUuid());
                if (targetOnline != null) {
                    plugin.getTabManager().updatePlayer(targetOnline);
                    plugin.getScoreboardManager().updateAll();
                }
            });
        });
    }
}

