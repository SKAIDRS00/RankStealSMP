package me.ranksteal;

import org.bukkit.Bukkit;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.entity.PlayerDeathEvent;
import org.bukkit.plugin.java.JavaPlugin;

import java.io.File;
import java.sql.*;
import java.util.UUID;

public class RankStealPlugin extends JavaPlugin implements Listener {

    private Connection conn;

    @Override
    public void onEnable() {
        Bukkit.getPluginManager().registerEvents(this, this);
        setupDB();
        getLogger().info("RankStealSMP Enabled");
    }

    private void setupDB() {
        try {
            if (!getDataFolder().exists()) getDataFolder().mkdirs();

            File dbFile = new File(getDataFolder(), "ranks.db");
            conn = DriverManager.getConnection("jdbc:sqlite:" + dbFile);

            Statement st = conn.createStatement();
            st.execute(
                "CREATE TABLE IF NOT EXISTS ranks (" +
                "uuid TEXT PRIMARY KEY," +
                "rank INTEGER" +
                ")"
            );

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private int getRank(UUID uuid) {
        try {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT rank FROM ranks WHERE uuid=?"
            );
            ps.setString(1, uuid.toString());

            ResultSet rs = ps.executeQuery();

            if (rs.next()) return rs.getInt("rank");

        } catch (Exception e) {
            e.printStackTrace();
        }
        return -1;
    }

    private void setRank(UUID uuid, int rank) {
        try {
            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO ranks(uuid, rank) VALUES(?, ?) " +
                "ON CONFLICT(uuid) DO UPDATE SET rank=?"
            );

            ps.setString(1, uuid.toString());
            ps.setInt(2, rank);
            ps.setInt(3, rank);

            ps.executeUpdate();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void swap(UUID k, UUID v) {
        int kr = getRank(k);
        int vr = getRank(v);

        if (kr == -1 || vr == -1) return;

        setRank(k, vr);
        setRank(v, kr);
    }

    @EventHandler
    public void onDeath(PlayerDeathEvent e) {
        Player v = e.getEntity();
        Player k = v.getKiller();

        if (k == null) return;

        swap(k.getUniqueId(), v.getUniqueId());

        k.sendMessage("§aRank stolen!");
        v.sendMessage("§cRank lost!");
    }
}