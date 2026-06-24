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

        final int finalTargetRank = targetRank;

        plugin.getDatabaseManager().getTotalPlayers().thenAccept(total -> {
            if (finalTargetRank > total + 1) {
                plugin.getServer().getScheduler().runTask(plugin, () ->
                        sender.sendMessage(mm.deserialize(
                                plugin.getConfig().getString("messages.setrank-invalid",
                                        "<red>Invalid rank. Must be between 1 and {max}.</red>")
                                        .replace("{max}", String.valueOf(total)))));
                return;
            }

            plugin.getDatabaseManager().getPlayerByRank(finalTargetRank).thenAccept(holder -> {
                Player online = Bukkit.getPlayerExact(targetName);
                PlayerData targetData = online != null
                        ? plugin.getRankManager().getCached(online.getUniqueId())
                        : null;

                if (targetData == null) {
                    plugin.getDatabaseManager().getPlayerByName(targetName).thenAccept(data -> {
                        if (data == null) {
                            plugin.getServer().getScheduler().runTask(plugin, () ->
                                    sender.sendMessage(mm.deserialize(
                                            plugin.getConfig().getString("messages.player-not-found",
                                                    "<red>Player not found.</red>"))));
                            return;
                        }
                        applySetRank(sender, data, holder, finalTargetRank);
                    });
                } else {
                    applySetRank(sender, targetData, holder, finalTargetRank);
                }
            });
        });

        return true;
    }

    private void applySetRank(CommandSender sender, PlayerData target, PlayerData holder, int targetRank) {
        int oldTargetRank = target.getRankNumber();

        if (holder != null && !holder.getUuid().equals(target.getUuid())) {
            holder.setRankNumber(oldTargetRank);
            target.setRankNumber(targetRank);

            plugin.getRankManager().putCache(target);
            plugin.getRankManager().putCache(holder);

            plugin.getDatabaseManager().swapRanks(target, holder).thenRun(() -> {
                plugin.getServer().getScheduler().runTask(plugin, () -> {
                    sender.sendMessage(mm.deserialize(
                            "<green>✓ Swapped: <white>" + target.getUsername() +
                            "</white> → <yellow>#" + targetRank + "</yellow>  |  <white>" +
                            holder.getUsername() + "</white> → <yellow>#" + oldTargetRank + "</yellow></green>"));
                    refreshOnlinePlayer(target);
                    refreshOnlinePlayer(holder);
                });
            });
        } else {
            target.setRankNumber(targetRank);
            plugin.getRankManager().putCache(target);

            plugin.getDatabaseManager().savePlayerData(target).thenRun(() -> {
                plugin.getServer().getScheduler().runTask(plugin, () -> {
                    sender.sendMessage(mm.deserialize(
                            plugin.getConfig().getString("messages.setrank-success",
                                    "<green>✓ Set <white>{player}</white>'s rank to <white>#{rank}</white>.</green>")
                                    .replace("{player}", target.getUsername())
                                    .replace("{rank}", String.valueOf(targetRank))));
                    refreshOnlinePlayer(target);
                });
            });
        }
    }

    private void refreshOnlinePlayer(PlayerData data) {
        Player online = Bukkit.getPlayer(data.getUuid());
        if (online != null) {
            plugin.getTabManager().updatePlayer(online);
            plugin.getScoreboardManager().show(online);
        }
    }
}