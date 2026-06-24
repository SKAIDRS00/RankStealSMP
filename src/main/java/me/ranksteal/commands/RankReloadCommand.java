package me.ranksteal.commands;

import me.ranksteal.RankStealPlugin;
import net.kyori.adventure.text.minimessage.MiniMessage;
import org.bukkit.command.Command;
import org.bukkit.command.CommandExecutor;
import org.bukkit.command.CommandSender;
import org.jetbrains.annotations.NotNull;

public class RankReloadCommand implements CommandExecutor {

    private final RankStealPlugin plugin;
    private final MiniMessage mm = MiniMessage.miniMessage();

    public RankReloadCommand(RankStealPlugin plugin) {
        this.plugin = plugin;
    }

    @Override
    public boolean onCommand(@NotNull CommandSender sender, @NotNull Command command,
                             @NotNull String label, @NotNull String[] args) {
        if (!sender.hasPermission("ranksteal.admin.reload")) {
            sender.sendMessage(mm.deserialize(
                    plugin.getConfig().getString("messages.no-permission", "<red>No permission.</red>")));
            return true;
        }

        plugin.reload();
        sender.sendMessage(mm.deserialize(
                plugin.getConfig().getString("messages.prefix", "<gradient:#FFD700:#FFA500><bold>[RS]</bold></gradient> ")
                        + plugin.getConfig().getString("messages.reload-success", "<green>✓ Config reloaded successfully.</green>")));
        return true;
    }
}

