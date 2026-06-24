package me.ranksteal.commands;

import me.ranksteal.RankStealPlugin;
import me.ranksteal.models.PlayerData;
import net.kyori.adventure.text.minimessage.MiniMessage;
import org.bukkit.command.Command;
import org.bukkit.command.CommandExecutor;
import org.bukkit.command.CommandSender;
import org.jetbrains.annotations.NotNull;

import java.util.List;

public class TopRanksCommand implements CommandExecutor {

    private static final int PAGE_SIZE = 10;
    private final RankStealPlugin plugin;
    private final MiniMessage mm = MiniMessage.miniMessage();

    public TopRanksCommand(RankStealPlugin plugin) {
        this.plugin = plugin;
    }

    @Override
    public boolean onCommand(@NotNull CommandSender sender, @NotNull Command command,
                             @NotNull String label, @NotNull String[] args) {
        if (!sender.hasPermission("ranksteal.topranks")) {
            sender.sendMessage(mm.deserialize(plugin.getConfig().getString("messages.no-permission", "<red>No permission.</red>")));
            return true;
        }

        int page = 1;
        if (args.length > 0) {
            try { page = Math.max(1, Integer.parseInt(args[0])); }
            catch (NumberFormatException e) { page = 1; }
        }

        final int finalPage = page;
        int offset = (page - 1) * PAGE_SIZE;

        plugin.getDatabaseManager().getTotalPlayers().thenAccept(total -> {
            int maxPage = Math.max(1, (int) Math.ceil((double) total / PAGE_SIZE));
            final int clampedPage = Math.min(finalPage, maxPage);
            int clampedOffset = (clampedPage - 1) * PAGE_SIZE;

            plugin.getDatabaseManager().getTopRanks(PAGE_SIZE, clampedOffset).thenAccept(entries -> {
                plugin.getServer().getScheduler().runTask(plugin, () ->
                        sendPage(sender, entries, clampedPage, maxPage));
            });
        });

        return true;
    }

    private void sendPage(CommandSender sender, List<PlayerData> entries, int page, int maxPage) {
        String prefix = plugin.getConfig().getString("messages.prefix", "<gradient:#FFD700:#FFA500><bold>[RS]</bold></gradient> ");
        sender.sendMessage(mm.deserialize(
                plugin.getConfig().getString("messages.topranks-header", "<gradient:#FFD700:#FFA500>━━━ TOP RANKS ━━━</gradient>")));

        for (int i = 0; i < entries.size(); i++) {
            PlayerData data = entries.get(i);
            int pos = ((page - 1) * PAGE_SIZE) + i + 1;
            String entry = plugin.getConfig().getString("messages.topranks-entry",
                    "<gray>{pos}. <white>{player}</white> → <yellow>#{rank}</yellow> <dark_gray>({kills} kills)</dark_gray></gray>")
                    .replace("{pos}", String.valueOf(pos))
                    .replace("{player}", data.getUsername())
                    .replace("{rank}", String.valueOf(data.getRankNumber()))
                    .replace("{kills}", String.valueOf(data.getKills()));
            sender.sendMessage(mm.deserialize(entry));
        }

        sender.sendMessage(mm.deserialize(
                plugin.getConfig().getString("messages.topranks-footer", "<gray>━━━━━━━━━━━━━━━━━━━━</gray>")));

        if (maxPage > 1) {
            String pageMsg = plugin.getConfig().getString("messages.topranks-page",
                    "<gray>Page {page}/{max_page} | /topranks {next}</gray>")
                    .replace("{page}", String.valueOf(page))
                    .replace("{max_page}", String.valueOf(maxPage))
                    .replace("{next}", String.valueOf(Math.min(page + 1, maxPage)));
            sender.sendMessage(mm.deserialize(pageMsg));
        }
    }
}

