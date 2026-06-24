package me.ranksteal;

import me.ranksteal.commands.RankCommand;
import me.ranksteal.commands.RankReloadCommand;
import me.ranksteal.commands.SetRankCommand;
import me.ranksteal.commands.TopRanksCommand;
import me.ranksteal.database.DatabaseManager;
import me.ranksteal.listeners.PlayerDeathListener;
import me.ranksteal.listeners.PlayerJoinListener;
import me.ranksteal.listeners.PlayerQuitListener;
import me.ranksteal.managers.RankManager;
import me.ranksteal.managers.ScoreboardManager;
import me.ranksteal.managers.TabManager;
import org.bukkit.plugin.java.JavaPlugin;

import java.util.Objects;
import java.util.logging.Level;

public final class RankStealPlugin extends JavaPlugin {

    private static RankStealPlugin instance;

    private DatabaseManager databaseManager;
    private RankManager rankManager;
    private ScoreboardManager scoreboardManager;
    private TabManager tabManager;

    @Override
    public void onEnable() {
        instance = this;

        saveDefaultConfig();

        if (!initDatabase()) {
            getLogger().severe("Failed to initialize database! Disabling plugin.");
            getServer().getPluginManager().disablePlugin(this);
            return;
        }

        rankManager = new RankManager(this, databaseManager);
        scoreboardManager = new ScoreboardManager(this);
        tabManager = new TabManager(this);

        registerListeners();
        registerCommands();

        getLogger().info("RankStealSMP v" + getDescription().getVersion() + " enabled.");
    }

    @Override
    public void onDisable() {
        if (scoreboardManager != null) scoreboardManager.removeAll();
        if (databaseManager != null) databaseManager.close();
        getLogger().info("RankStealSMP disabled.");
    }

    private boolean initDatabase() {
        try {
            databaseManager = new DatabaseManager(this);
            databaseManager.init();
            return true;
        } catch (Exception e) {
            getLogger().log(Level.SEVERE, "Database initialization failed", e);
            return false;
        }
    }

    private void registerListeners() {
        var pm = getServer().getPluginManager();
        pm.registerEvents(new PlayerDeathListener(this), this);
        pm.registerEvents(new PlayerJoinListener(this), this);
        pm.registerEvents(new PlayerQuitListener(this), this);
    }

    private void registerCommands() {
        Objects.requireNonNull(getCommand("rank")).setExecutor(new RankCommand(this));
        Objects.requireNonNull(getCommand("topranks")).setExecutor(new TopRanksCommand(this));
        Objects.requireNonNull(getCommand("setrank")).setExecutor(new SetRankCommand(this));
        Objects.requireNonNull(getCommand("rankreload")).setExecutor(new RankReloadCommand(this));
    }

    public void reload() {
        reloadConfig();
        scoreboardManager.reload();
        tabManager.reload();
    }

    public static RankStealPlugin getInstance() {
        return instance;
    }

    public DatabaseManager getDatabaseManager() {
        return databaseManager;
    }

    public RankManager getRankManager() {
        return rankManager;
    }

    public ScoreboardManager getScoreboardManager() {
        return scoreboardManager;
    }

    public TabManager getTabManager() {
        return tabManager;
    }
}
