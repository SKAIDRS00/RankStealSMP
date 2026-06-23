package me.ranksteal;

import org.bukkit.Bukkit;
import org.bukkit.command.Command;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.Player;
import org.bukkit.event.Listener;
import org.bukkit.plugin.java.JavaPlugin;

import java.util.HashMap;
import java.util.UUID;

public class RankStealPlugin extends JavaPlugin implements Listener {

    private final HashMap<UUID, Integer> ranks = new HashMap<>();

    @Override
    public void onEnable() {
        Bukkit.getPluginManager().registerEvents(this, this);
        getLogger().info("RankStealSMP Enabled");
    }

    private int getRank(UUID uuid) {
        return ranks.getOrDefault(uuid, 1);
    }

    private void setRank(UUID uuid, int rank) {
        ranks.put(uuid, rank);
    }

    @Override
    public boolean onCommand(CommandSender sender, Command cmd, String label, String[] args) {

        // /rank
        if (cmd.getName().equalsIgnoreCase("rank")) {

            if (args.length == 0) {
                if (!(sender instanceof Player p)) return true;
                p.sendMessage("Your Rank: " + getRank(p.getUniqueId()));
                return true;
            }

            Player target = Bukkit.getPlayer(args[0]);
            if (target == null) {
                sender.sendMessage("Player not found");
                return true;
            }

            sender.sendMessage(target.getName() + " Rank: " + getRank(target.getUniqueId()));
            return true;
        }

        // /setrank
        if (cmd.getName().equalsIgnoreCase("setrank")) {

            if (!sender.hasPermission("ranksteal.admin")) {
                sender.sendMessage("No permission");
                return true;
            }

            if (args.length != 2) {
                sender.sendMessage("/setrank <player> <rank>");
                return true;
            }

            Player target = Bukkit.getPlayer(args[0]);
            if (target == null) {
                sender.sendMessage("Player not found");
                return true;
            }

            int rank;
            try {
                rank = Integer.parseInt(args[1]);
            } catch (Exception e) {
                sender.sendMessage("Invalid number");
                return true;
            }

            setRank(target.getUniqueId(), rank);
            sender.sendMessage("Rank set!");
            return true;
        }

        return false;
    }
}