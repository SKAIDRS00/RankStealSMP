#!/bin/bash
echo "Creating RankStealSMP project..."

mkdir -p src/main/java/me/ranksteal/{commands,listeners,managers,database,engine,models,api}
mkdir -p src/main/resources
mkdir -p .github/workflows

cat > "pom.xml" << 'HEREDOC_POM_XML'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>me.ranksteal</groupId>
    <artifactId>RankStealSMP</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <name>RankStealSMP</name>
    <description>Premium rank-stealing SMP plugin for Paper 1.21.1</description>

    <properties>
        <java.version>21</java.version>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <repositories>
        <repository>
            <id>papermc</id>
            <url>https://repo.papermc.io/repository/maven-public/</url>
        </repository>
        <repository>
            <id>placeholderapi</id>
            <url>https://repo.extendedclip.com/content/repositories/placeholderapi/</url>
        </repository>
    </repositories>

    <dependencies>
        <dependency>
            <groupId>io.papermc.paper</groupId>
            <artifactId>paper-api</artifactId>
            <version>1.21.1-R0.1-SNAPSHOT</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.xerial</groupId>
            <artifactId>sqlite-jdbc</artifactId>
            <version>3.46.0.0</version>
            <scope>compile</scope>
        </dependency>
        <dependency>
            <groupId>me.clip</groupId>
            <artifactId>placeholderapi</artifactId>
            <version>2.11.6</version>
            <scope>provided</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-shade-plugin</artifactId>
                <version>3.5.3</version>
                <executions>
                    <execution>
                        <phase>package</phase>
                        <goals>
                            <goal>shade</goal>
                        </goals>
                        <configuration>
                            <createDependencyReducedPom>false</createDependencyReducedPom>
                            <finalName>RankStealSMP-${project.version}</finalName>
                            <relocations>
                                <relocation>
                                    <pattern>org.sqlite</pattern>
                                    <shadedPattern>me.ranksteal.libs.sqlite</shadedPattern>
                                </relocation>
                            </relocations>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.13.0</version>
                <configuration>
                    <source>21</source>
                    <target>21</target>
                </configuration>
            </plugin>
        </plugins>
        <resources>
            <resource>
                <directory>src/main/resources</directory>
                <filtering>true</filtering>
            </resource>
        </resources>
    </build>
</project>

HEREDOC_POM_XML

cat > "src/main/java/me/ranksteal/RankStealPlugin.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_RANKSTEALPLUGIN_JAVA'
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

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_RANKSTEALPLUGIN_JAVA

cat > "src/main/java/me/ranksteal/api/RankStealAPI.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_API_RANKSTEALAPI_JAVA'
package me.ranksteal.api;

import me.ranksteal.RankStealPlugin;
import me.ranksteal.models.PlayerData;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

/**
 * Public API for RankStealSMP.
 * Other plugins can use this to read and interact with rank data.
 *
 * Usage:
 *   RankStealAPI api = RankStealAPI.get();
 *   api.getPlayerData(uuid).thenAccept(data -> { ... });
 */
public class RankStealAPI {

    private static RankStealAPI instance;
    private final RankStealPlugin plugin;

    private RankStealAPI(RankStealPlugin plugin) {
        this.plugin = plugin;
    }

    public static void init(RankStealPlugin plugin) {
        instance = new RankStealAPI(plugin);
    }

    public static RankStealAPI get() {
        if (instance == null) throw new IllegalStateException("RankStealSMP is not loaded.");
        return instance;
    }

    /** Get a player's data by UUID (async). Returns null if never joined. */
    public CompletableFuture<PlayerData> getPlayerData(UUID uuid) {
        PlayerData cached = plugin.getRankManager().getCached(uuid);
        if (cached != null) return CompletableFuture.completedFuture(cached);
        return plugin.getDatabaseManager().getPlayerData(uuid);
    }

    /** Get player at a specific rank number (async). */
    public CompletableFuture<PlayerData> getPlayerAtRank(int rank) {
        return plugin.getDatabaseManager().getPlayerByRank(rank);
    }

    /** Get the top N ranked players (async). */
    public CompletableFuture<List<PlayerData>> getTopRanks(int limit) {
        return plugin.getDatabaseManager().getTopRanks(limit, 0);
    }

    /** Get total registered players. */
    public CompletableFuture<Integer> getTotalPlayers() {
        return plugin.getDatabaseManager().getTotalPlayers();
    }

    /** Get rank number for a UUID (cached, or -1 if not loaded). */
    public int getCachedRank(UUID uuid) {
        PlayerData data = plugin.getRankManager().getCached(uuid);
        return data != null ? data.getRankNumber() : -1;
    }
}

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_API_RANKSTEALAPI_JAVA

cat > "src/main/java/me/ranksteal/commands/RankCommand.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_COMMANDS_RANKCOMMAND_JAVA'
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

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_COMMANDS_RANKCOMMAND_JAVA

cat > "src/main/java/me/ranksteal/commands/RankReloadCommand.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_COMMANDS_RANKRELOADCOMMAND_JAVA'
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

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_COMMANDS_RANKRELOADCOMMAND_JAVA

cat > "src/main/java/me/ranksteal/commands/SetRankCommand.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_COMMANDS_SETRANKCOMMAND_JAVA'
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

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_COMMANDS_SETRANKCOMMAND_JAVA

cat > "src/main/java/me/ranksteal/commands/TopRanksCommand.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_COMMANDS_TOPRANKSCOMMAND_JAVA'
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

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_COMMANDS_TOPRANKSCOMMAND_JAVA

cat > "src/main/java/me/ranksteal/database/DatabaseManager.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_DATABASE_DATABASEMANAGER_JAVA'
package me.ranksteal.database;

import me.ranksteal.RankStealPlugin;
import me.ranksteal.models.PlayerData;
import org.bukkit.scheduler.BukkitRunnable;

import java.io.File;
import java.sql.*;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.function.Consumer;
import java.util.logging.Level;

public class DatabaseManager {

    private final RankStealPlugin plugin;
    private Connection connection;

    public DatabaseManager(RankStealPlugin plugin) {
        this.plugin = plugin;
    }

    public void init() throws SQLException {
        File dbFile = new File(plugin.getDataFolder(), plugin.getConfig().getString("database.file", "ranksteal.db"));
        plugin.getDataFolder().mkdirs();

        String url = "jdbc:sqlite:" + dbFile.getAbsolutePath();
        connection = DriverManager.getConnection(url);

        try (Statement stmt = connection.createStatement()) {
            stmt.execute("PRAGMA journal_mode=WAL");
            stmt.execute("PRAGMA synchronous=NORMAL");
        }

        createTables();
        plugin.getLogger().info("SQLite database initialized at: " + dbFile.getAbsolutePath());
    }

    private void createTables() throws SQLException {
        String sql = """
                CREATE TABLE IF NOT EXISTS player_ranks (
                    uuid         TEXT PRIMARY KEY,
                    username     TEXT NOT NULL,
                    rank_number  INTEGER NOT NULL UNIQUE,
                    kills        INTEGER NOT NULL DEFAULT 0,
                    deaths       INTEGER NOT NULL DEFAULT 0,
                    last_seen    INTEGER NOT NULL DEFAULT 0
                )
                """;
        try (Statement stmt = connection.createStatement()) {
            stmt.execute(sql);
            stmt.execute("CREATE INDEX IF NOT EXISTS idx_rank_number ON player_ranks(rank_number)");
        }
    }

    public void close() {
        try {
            if (connection != null && !connection.isClosed()) {
                connection.close();
            }
        } catch (SQLException e) {
            plugin.getLogger().log(Level.WARNING, "Error closing database connection", e);
        }
    }

    public CompletableFuture<PlayerData> getPlayerData(UUID uuid) {
        return async(() -> {
            String sql = "SELECT * FROM player_ranks WHERE uuid = ?";
            try (PreparedStatement ps = connection.prepareStatement(sql)) {
                ps.setString(1, uuid.toString());
                ResultSet rs = ps.executeQuery();
                if (rs.next()) return fromResultSet(rs);
            } catch (SQLException e) {
                plugin.getLogger().log(Level.SEVERE, "Error fetching player data for " + uuid, e);
            }
            return null;
        });
    }

    public CompletableFuture<Void> savePlayerData(PlayerData data) {
        return async(() -> {
            String sql = """
                    INSERT INTO player_ranks (uuid, username, rank_number, kills, deaths, last_seen)
                    VALUES (?, ?, ?, ?, ?, ?)
                    ON CONFLICT(uuid) DO UPDATE SET
                        username    = excluded.username,
                        rank_number = excluded.rank_number,
                        kills       = excluded.kills,
                        deaths      = excluded.deaths,
                        last_seen   = excluded.last_seen
                    """;
            try (PreparedStatement ps = connection.prepareStatement(sql)) {
                ps.setString(1, data.getUuid().toString());
                ps.setString(2, data.getUsername());
                ps.setInt(3, data.getRankNumber());
                ps.setInt(4, data.getKills());
                ps.setInt(5, data.getDeaths());
                ps.setLong(6, data.getLastSeen());
                ps.executeUpdate();
            } catch (SQLException e) {
                plugin.getLogger().log(Level.SEVERE, "Error saving player data for " + data.getUuid(), e);
            }
            return null;
        });
    }

    public CompletableFuture<Void> swapRanks(PlayerData a, PlayerData b) {
        return async(() -> {
            try {
                connection.setAutoCommit(false);
                int rankA = a.getRankNumber();
                int rankB = b.getRankNumber();

                String tempSql = "UPDATE player_ranks SET rank_number = -1 WHERE uuid = ?";
                String setSql  = "UPDATE player_ranks SET rank_number = ? WHERE uuid = ?";

                try (PreparedStatement temp = connection.prepareStatement(tempSql);
                     PreparedStatement set  = connection.prepareStatement(setSql)) {

                    temp.setString(1, a.getUuid().toString());
                    temp.executeUpdate();

                    set.setInt(1, rankA);
                    set.setString(2, b.getUuid().toString());
                    set.executeUpdate();

                    set.setInt(1, rankB);
                    set.setString(2, a.getUuid().toString());
                    set.executeUpdate();
                }

                connection.commit();
            } catch (SQLException e) {
                try { connection.rollback(); } catch (SQLException ignored) {}
                plugin.getLogger().log(Level.SEVERE, "Error swapping ranks", e);
            } finally {
                try { connection.setAutoCommit(true); } catch (SQLException ignored) {}
            }
            return null;
        });
    }

    public CompletableFuture<Integer> getNextRankNumber() {
        return async(() -> {
            String sql = "SELECT COALESCE(MAX(rank_number), 0) + 1 FROM player_ranks";
            try (Statement stmt = connection.createStatement();
                 ResultSet rs = stmt.executeQuery(sql)) {
                if (rs.next()) return rs.getInt(1);
            } catch (SQLException e) {
                plugin.getLogger().log(Level.SEVERE, "Error getting next rank number", e);
            }
            return 1;
        });
    }

    public CompletableFuture<List<PlayerData>> getTopRanks(int limit, int offset) {
        return async(() -> {
            List<PlayerData> list = new ArrayList<>();
            String sql = "SELECT * FROM player_ranks ORDER BY rank_number ASC LIMIT ? OFFSET ?";
            try (PreparedStatement ps = connection.prepareStatement(sql)) {
                ps.setInt(1, limit);
                ps.setInt(2, offset);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) list.add(fromResultSet(rs));
            } catch (SQLException e) {
                plugin.getLogger().log(Level.SEVERE, "Error fetching top ranks", e);
            }
            return list;
        });
    }

    public CompletableFuture<Integer> getTotalPlayers() {
        return async(() -> {
            String sql = "SELECT COUNT(*) FROM player_ranks";
            try (Statement stmt = connection.createStatement();
                 ResultSet rs = stmt.executeQuery(sql)) {
                if (rs.next()) return rs.getInt(1);
            } catch (SQLException e) {
                plugin.getLogger().log(Level.SEVERE, "Error getting total players", e);
            }
            return 0;
        });
    }

    public CompletableFuture<PlayerData> getPlayerByRank(int rankNumber) {
        return async(() -> {
            String sql = "SELECT * FROM player_ranks WHERE rank_number = ?";
            try (PreparedStatement ps = connection.prepareStatement(sql)) {
                ps.setInt(1, rankNumber);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) return fromResultSet(rs);
            } catch (SQLException e) {
                plugin.getLogger().log(Level.SEVERE, "Error fetching player by rank " + rankNumber, e);
            }
            return null;
        });
    }

    public CompletableFuture<PlayerData> getPlayerByName(String name) {
        return async(() -> {
            String sql = "SELECT * FROM player_ranks WHERE LOWER(username) = LOWER(?)";
            try (PreparedStatement ps = connection.prepareStatement(sql)) {
                ps.setString(1, name);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) return fromResultSet(rs);
            } catch (SQLException e) {
                plugin.getLogger().log(Level.SEVERE, "Error fetching player by name " + name, e);
            }
            return null;
        });
    }

    private PlayerData fromResultSet(ResultSet rs) throws SQLException {
        return new PlayerData(
                UUID.fromString(rs.getString("uuid")),
                rs.getString("username"),
                rs.getInt("rank_number"),
                rs.getInt("kills"),
                rs.getInt("deaths"),
                rs.getLong("last_seen")
        );
    }

    private <T> CompletableFuture<T> async(SqlSupplier<T> supplier) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                return supplier.get();
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        });
    }

    @FunctionalInterface
    private interface SqlSupplier<T> {
        T get() throws Exception;
    }
}

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_DATABASE_DATABASEMANAGER_JAVA

cat > "src/main/java/me/ranksteal/engine/SwapEngine.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_ENGINE_SWAPENGINE_JAVA'
package me.ranksteal.engine;

import me.ranksteal.RankStealPlugin;
import me.ranksteal.database.DatabaseManager;
import me.ranksteal.managers.RankManager;
import me.ranksteal.models.PlayerData;
import net.kyori.adventure.text.minimessage.MiniMessage;
import net.kyori.adventure.title.Title;
import org.bukkit.Sound;
import org.bukkit.entity.Player;

import java.time.Duration;
import java.util.logging.Level;

public class SwapEngine {

    private final RankStealPlugin plugin;
    private final RankManager rankManager;
    private final DatabaseManager db;
    private final MiniMessage mm = MiniMessage.miniMessage();

    public SwapEngine(RankStealPlugin plugin, RankManager rankManager, DatabaseManager db) {
        this.plugin = plugin;
        this.rankManager = rankManager;
        this.db = db;
    }

    public void processKill(Player killer, Player victim) {
        PlayerData killerData = rankManager.getCached(killer.getUniqueId());
        PlayerData victimData = rankManager.getCached(victim.getUniqueId());

        if (killerData == null || victimData == null) return;

        int killerRank = killerData.getRankNumber();
        int victimRank = victimData.getRankNumber();

        if (killerRank == victimRank) return;
        if (killerRank <= victimRank) return;

        int stolenRank = victimRank;

        killerData.setRankNumber(victimRank);
        victimData.setRankNumber(killerRank);
        killerData.incrementKills();
        victimData.incrementDeaths();

        db.swapRanks(killerData, victimData).thenRun(() -> {
            db.savePlayerData(killerData);
            db.savePlayerData(victimData);
        }).exceptionally(ex -> {
            plugin.getLogger().log(Level.SEVERE, "Swap failed — rolling back cache", ex);
            killerData.setRankNumber(killerRank);
            victimData.setRankNumber(victimRank);
            return null;
        });

        plugin.getServer().getScheduler().runTask(plugin, () -> {
            notifyKiller(killer, killerData, killerRank, stolenRank, victim.getName());
            notifyVictim(victim, victimData, killerRank, killer.getName());
            plugin.getScoreboardManager().updateAll();
            plugin.getTabManager().updatePlayer(killer);
            plugin.getTabManager().updatePlayer(victim);
        });
    }

    private void notifyKiller(Player killer, PlayerData data, int oldRank, int stolenRank, String victimName) {
        String msg = plugin.getConfig().getString("messages.rank-stolen-attacker",
                "<gradient:#FF4500:#FFD700>⚔ You stole <white>#{stolen_rank}</white> from <red>{victim}</red>!</gradient>")
                .replace("{stolen_rank}", String.valueOf(stolenRank))
                .replace("{victim}", victimName)
                .replace("{old_rank}", String.valueOf(oldRank))
                .replace("{new_rank}", String.valueOf(data.getRankNumber()));
        killer.sendMessage(mm.deserialize(msg));

        if (plugin.getConfig().getBoolean("actionbar.enabled", true)) {
            String ab = plugin.getConfig().getString("actionbar.kill-message",
                    "<gradient:#FF4500:#FFD700>⚔ You stole rank #{stolen_rank} from {victim}!</gradient>")
                    .replace("{stolen_rank}", String.valueOf(stolenRank))
                    .replace("{victim}", victimName);
            killer.sendActionBar(mm.deserialize(ab));
        }

        Title title = Title.title(
                mm.deserialize("<gradient:#FFD700:#FF4500><bold>RANK STOLEN!</bold></gradient>"),
                mm.deserialize("<gray>#" + oldRank + " <white>→</white> <yellow>#" + data.getRankNumber() + "</yellow></gray>"),
                Title.Times.times(Duration.ofMillis(200), Duration.ofMillis(2500), Duration.ofMillis(500))
        );
        killer.showTitle(title);

        if (plugin.getConfig().getBoolean("sounds.rank-steal.enabled", true)) {
            String soundName = plugin.getConfig().getString("sounds.rank-steal.sound", "ENTITY_PLAYER_LEVELUP");
            float volume = (float) plugin.getConfig().getDouble("sounds.rank-steal.volume", 1.0);
            float pitch  = (float) plugin.getConfig().getDouble("sounds.rank-steal.pitch", 1.2);
            try {
                killer.playSound(killer.getLocation(), Sound.valueOf(soundName), volume, pitch);
            } catch (IllegalArgumentException ignored) {}
        }
    }

    private void notifyVictim(Player victim, PlayerData data, int newRank, String killerName) {
        String msg = plugin.getConfig().getString("messages.rank-stolen-victim",
                "<gradient:#FF0000:#FF6347>💀 <white>{killer}</white> stole your rank! You dropped to <white>#{new_rank}</white></gradient>")
                .replace("{killer}", killerName)
                .replace("{new_rank}", String.valueOf(data.getRankNumber()));
        victim.sendMessage(mm.deserialize(msg));

        Title title = Title.title(
                mm.deserialize("<red><bold>RANK LOST!</bold></red>"),
                mm.deserialize("<gray>Dropped to <white>#" + data.getRankNumber() + "</white></gray>"),
                Title.Times.times(Duration.ofMillis(200), Duration.ofMillis(2500), Duration.ofMillis(500))
        );
        victim.showTitle(title);
    }
}

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_ENGINE_SWAPENGINE_JAVA

cat > "src/main/java/me/ranksteal/listeners/PlayerDeathListener.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_LISTENERS_PLAYERDEATHLISTENER_JAVA'
package me.ranksteal.listeners;

import me.ranksteal.RankStealPlugin;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.entity.PlayerDeathEvent;

public class PlayerDeathListener implements Listener {

    private final RankStealPlugin plugin;

    public PlayerDeathListener(RankStealPlugin plugin) {
        this.plugin = plugin;
    }

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    public void onPlayerDeath(PlayerDeathEvent event) {
        Player victim = event.getEntity();
        Player killer = victim.getKiller();

        if (killer == null) return;
        if (killer.equals(victim)) return;

        plugin.getRankManager().processKill(killer, victim);
    }
}

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_LISTENERS_PLAYERDEATHLISTENER_JAVA

cat > "src/main/java/me/ranksteal/listeners/PlayerJoinListener.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_LISTENERS_PLAYERJOINLISTENER_JAVA'
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

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_LISTENERS_PLAYERJOINLISTENER_JAVA

cat > "src/main/java/me/ranksteal/listeners/PlayerQuitListener.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_LISTENERS_PLAYERQUITLISTENER_JAVA'
package me.ranksteal.listeners;

import me.ranksteal.RankStealPlugin;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerQuitEvent;

public class PlayerQuitListener implements Listener {

    private final RankStealPlugin plugin;

    public PlayerQuitListener(RankStealPlugin plugin) {
        this.plugin = plugin;
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void onPlayerQuit(PlayerQuitEvent event) {
        plugin.getRankManager().unloadPlayer(event.getPlayer().getUniqueId());
        plugin.getScoreboardManager().remove(event.getPlayer());
    }
}

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_LISTENERS_PLAYERQUITLISTENER_JAVA

cat > "src/main/java/me/ranksteal/managers/RankManager.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_MANAGERS_RANKMANAGER_JAVA'
package me.ranksteal.managers;

import me.ranksteal.RankStealPlugin;
import me.ranksteal.database.DatabaseManager;
import me.ranksteal.engine.SwapEngine;
import me.ranksteal.models.PlayerData;
import org.bukkit.entity.Player;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Level;

public class RankManager {

    private final RankStealPlugin plugin;
    private final DatabaseManager db;
    private final SwapEngine swapEngine;

    private final Map<UUID, PlayerData> cache = new ConcurrentHashMap<>();

    public RankManager(RankStealPlugin plugin, DatabaseManager db) {
        this.plugin = plugin;
        this.db = db;
        this.swapEngine = new SwapEngine(plugin, this, db);
    }

    public void loadPlayer(Player player) {
        UUID uuid = player.getUniqueId();
        db.getPlayerData(uuid).thenAccept(data -> {
            if (data == null) {
                registerNewPlayer(player);
            } else {
                data.setUsername(player.getName());
                data.setLastSeen(System.currentTimeMillis());
                cache.put(uuid, data);
                db.savePlayerData(data);
                plugin.getScoreboardManager().show(player);
                plugin.getTabManager().updatePlayer(player);
                plugin.getServer().getScheduler().runTask(plugin, () ->
                        plugin.getScoreboardManager().show(player));
            }
        }).exceptionally(ex -> {
            plugin.getLogger().log(Level.SEVERE, "Failed to load player " + player.getName(), ex);
            return null;
        });
    }

    private void registerNewPlayer(Player player) {
        db.getNextRankNumber().thenAccept(nextRank -> {
            PlayerData data = new PlayerData(
                    player.getUniqueId(),
                    player.getName(),
                    nextRank,
                    0,
                    0,
                    System.currentTimeMillis()
            );
            cache.put(player.getUniqueId(), data);
            db.savePlayerData(data).thenRun(() -> {
                plugin.getServer().getScheduler().runTask(plugin, () -> {
                    plugin.getScoreboardManager().show(player);
                    plugin.getTabManager().updatePlayer(player);
                    broadcastNewPlayer(player, nextRank);
                });
            });
        });
    }

    private void broadcastNewPlayer(Player player, int rank) {
        String msg = plugin.getConfig().getString("messages.new-player-join",
                "<gradient:#00FF88:#00BFFF>✦ {player} joined! Rank: #{rank}</gradient>");
        String formatted = msg
                .replace("{player}", player.getName())
                .replace("{rank}", String.valueOf(rank));
        plugin.getServer().broadcast(plugin.getRankManager().mini(formatted));
    }

    public void unloadPlayer(UUID uuid) {
        PlayerData data = cache.remove(uuid);
        if (data != null) {
            data.setLastSeen(System.currentTimeMillis());
            db.savePlayerData(data);
        }
    }

    public void processKill(Player killer, Player victim) {
        swapEngine.processKill(killer, victim);
    }

    public PlayerData getCached(UUID uuid) {
        return cache.get(uuid);
    }

    public void putCache(PlayerData data) {
        cache.put(data.getUuid(), data);
    }

    public net.kyori.adventure.text.Component mini(String miniMessage) {
        return net.kyori.adventure.text.minimessage.MiniMessage.miniMessage().deserialize(miniMessage);
    }

    public String getRankPrefix(int rank) {
        var top3 = plugin.getConfig().getConfigurationSection("rank.top3-prefixes");
        if (top3 != null && top3.contains(String.valueOf(rank))) {
            return top3.getString(String.valueOf(rank), "");
        }
        return plugin.getConfig().getString("rank.prefix-format", "<gradient:#FFD700:#FFA500>[#{rank}]</gradient> ")
                .replace("{rank}", String.valueOf(rank));
    }

    public SwapEngine getSwapEngine() {
        return swapEngine;
    }
}

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_MANAGERS_RANKMANAGER_JAVA

cat > "src/main/java/me/ranksteal/managers/ScoreboardManager.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_MANAGERS_SCOREBOARDMANAGER_JAVA'
package me.ranksteal.managers;

import me.ranksteal.RankStealPlugin;
import me.ranksteal.models.PlayerData;
import net.kyori.adventure.text.minimessage.MiniMessage;
import org.bukkit.Bukkit;
import org.bukkit.entity.Player;
import org.bukkit.scheduler.BukkitTask;
import org.bukkit.scoreboard.*;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public class ScoreboardManager {

    private final RankStealPlugin plugin;
    private final MiniMessage mm = MiniMessage.miniMessage();
    private final Map<UUID, Scoreboard> boards = new HashMap<>();
    private BukkitTask task;

    public ScoreboardManager(RankStealPlugin plugin) {
        this.plugin = plugin;
        startUpdater();
    }

    private void startUpdater() {
        int interval = plugin.getConfig().getInt("scoreboard.update-interval", 20);
        task = Bukkit.getScheduler().runTaskTimer(plugin, this::updateAll, interval, interval);
    }

    public void show(Player player) {
        if (!plugin.getConfig().getBoolean("scoreboard.enabled", true)) return;

        org.bukkit.scoreboard.ScoreboardManager manager = Bukkit.getScoreboardManager();
        Scoreboard board = manager.getNewScoreboard();
        Objective obj = board.registerNewObjective("ranksteal", Criteria.DUMMY,
                mm.deserialize(plugin.getConfig().getString("scoreboard.title",
                        "<gradient:#FFD700:#FF4500><bold>✦ RANK STEAL SMP ✦</bold></gradient>")));
        obj.setDisplaySlot(DisplaySlot.SIDEBAR);

        boards.put(player.getUniqueId(), board);
        player.setScoreboard(board);
        update(player, obj);
    }

    public void update(Player player, Objective obj) {
        PlayerData data = plugin.getRankManager().getCached(player.getUniqueId());
        if (data == null) return;

        int online = Bukkit.getOnlinePlayers().size();

        setLine(obj, 15, " ");
        setLine(obj, 14, "§e§lYour Rank");
        setLine(obj, 13, "§f  #" + data.getRankNumber());
        setLine(obj, 12, " §");
        setLine(obj, 11, "§e§lStats");
        setLine(obj, 10, "§f  Kills: §a" + data.getKills());
        setLine(obj,  9, "§f  Deaths: §c" + data.getDeaths());
        setLine(obj,  8, "§f  K/D: §b" + data.getKDR());
        setLine(obj,  7, " §§");
        setLine(obj,  6, "§e§lServer");
        setLine(obj,  5, "§f  Online: §a" + online);
        setLine(obj,  4, " §§§");
        setLine(obj,  3, "§7play.yourserver.net");
    }

    private void setLine(Objective obj, int score, String text) {
        Score s = obj.getScore(text);
        s.setScore(score);
    }

    public void updateAll() {
        for (Player player : Bukkit.getOnlinePlayers()) {
            Scoreboard board = boards.get(player.getUniqueId());
            if (board == null) continue;
            Objective obj = board.getObjective("ranksteal");
            if (obj == null) continue;
            update(player, obj);
        }
    }

    public void remove(Player player) {
        boards.remove(player.getUniqueId());
        player.setScoreboard(Bukkit.getScoreboardManager().getMainScoreboard());
    }

    public void removeAll() {
        for (Player player : Bukkit.getOnlinePlayers()) {
            remove(player);
        }
        if (task != null) task.cancel();
    }

    public void reload() {
        if (task != null) task.cancel();
        boards.clear();
        for (Player player : Bukkit.getOnlinePlayers()) {
            show(player);
        }
        startUpdater();
    }
}

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_MANAGERS_SCOREBOARDMANAGER_JAVA

cat > "src/main/java/me/ranksteal/managers/TabManager.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_MANAGERS_TABMANAGER_JAVA'
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

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_MANAGERS_TABMANAGER_JAVA

cat > "src/main/java/me/ranksteal/models/PlayerData.java" << 'HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_MODELS_PLAYERDATA_JAVA'
package me.ranksteal.models;

import java.util.UUID;

public class PlayerData {

    private final UUID uuid;
    private String username;
    private int rankNumber;
    private int kills;
    private int deaths;
    private long lastSeen;

    public Pluuid, String username, int rankNumber, int kills, int deaths, long lastSeen) {
        this.uuid = uuid;
        this.username = username;
        this.rankNumber = rankNumber;
        this.kills = kills;
        this.deaths = deaths;
        this.lastSeen = lastSeen;
    }

    public UUID getUuid() { return uuid; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public int getRankNumber() { return rankNumber; }
    public void setRankNumber(int rankNumber) { this.rankNumber = rankNumber; }

    public int getKills() { return kills; }
    public void incrementKills() { this.kills++; }

    public int getDeaths() { return deaths; }
    public void incrementDeaths() { this.deaths++; }

    public long getLastSeen() { return lastSeen; }
    public void setLastSeen(long lastSeen) { this.lastSeen = lastSeen; }

    public double getKDR() {
        if (deaths == 0) return kills;
        return Math.round((double) kills / deaths * 100.0) / 100.0;
    }

    @Override
    public String toString() {
        return "PlayerData{uuid=" + uuid + ", name=" + username + ", rank=#" + rankNumber + "}";
    }
}

HEREDOC_SRC_MAIN_JAVA_ME_RANKSTEAL_MODELS_PLAYERDATA_JAVA

cat > "src/main/resources/config.yml" << 'HEREDOC_SRC_MAIN_RESOURCES_CONFIG_YML'
# ╔══════════════════════════════════════╗
# ║       RankStealSMP Configuration     ║
# ╚══════════════════════════════════════╝

database:
  # SQLite database file name (in plugin folder)
  file: ranksteal.db

rank:
  # Format for rank display (supports MiniMessage)
  # Placeholders: {rank} {player}
  prefix-format: "<gradient:#FFD700:#FFA500>[#{rank}]</gradient> "
  top3-prefixes:
    1: "<gradient:#FFD700:#FF8C00>☆ [#1]</gradient> "
    2: "<gradient:#C0C0C0:#A9A9A9>☆ [#2]</gradient> "
    3: "<gradient:#CD7F32:#8B4513>☆ [#3]</gradient> "

scoreboard:
  enabled: true
  title: "<gradient:#FFD700:#FF4500><bold>✦ RANK STEAL SMP ✦</bold></gradient>"
  update-interval: 20  # ticks (20 = 1 second)

tab:
  enabled: true
  header: "\n<gradient:#FFD700:#FFA500><bold>✦ RankSteal SMP ✦</bold></gradient>\n"
  footer: "\n<gray>Players Online: <white>{online}</white></gray>\n"

actionbar:
  enabled: true
  # Shown after a kill
  kill-message: "<gradient:#FF4500:#FFD700>⚔ You stole rank #{stolen_rank} from {victim}!</gradient>"

sounds:
  rank-steal:
    enabled: true
    sound: ENTITY_PLAYER_LEVELUP
    volume: 1.0
    pitch: 1.2
  new-player:
    enabled: true
    sound: BLOCK_NOTE_BLOCK_PLING
    volume: 1.0
    pitch: 1.0

messages:
  prefix: "<gradient:#FFD700:#FFA500><bold>[RS]</bold></gradient> "
  rank-info: "<yellow>Your rank: <white>#{rank}</white> | Kills: <white>{kills}</white> | Deaths: <white>{deaths}</white></yellow>"
  rank-stolen-attacker: "<gradient:#FF4500:#FFD700>⚔ You stole <white>#{stolen_rank}</white> from <red>{victim}</red>! Your rank: <white>#{new_rank}</white></gradient>"
  rank-stolen-victim: "<gradient:#FF0000:#FF6347>💀 <white>{killer}</white> stole your rank! You dropped to <white>#{new_rank}</white></gradient>"
  new-player-join: "<gradient:#00FF88:#00BFFF>✦ {player} joined the SMP! Rank: <white>#{rank}</white></gradient>"
  player-not-found: "<red>Player not found or never joined.</red>"
  no-permission: "<red>You don't have permission to do that.</red>"
  reload-success: "<green>✓ Config reloaded successfully.</green>"
  setrank-success: "<green>✓ Set <white>{player}</white>'s rank to <white>#{rank}</white>.</green>"
  setrank-invalid: "<red>Invalid rank number. Must be between 1 and {max}.</red>"
  setrank-occupied: "<red>Rank #{rank} is already taken by {holder}.</red>"
  topranks-header: "<gradient:#FFD700:#FFA500>━━━━━ TOP RANKS ━━━━━</gradient>"
  topranks-entry: "<gray>{pos}. <white>{player}</white> → <yellow>#{rank}</yellow> <dark_gray>({kills} kills)</dark_gray></gray>"
  topranks-footer: "<gray>━━━━━━━━━━━━━━━━━━━━</gray>"
  topranks-page: "<gray>Page {page}/{max_page} | /topranks {next}</gray>"

HEREDOC_SRC_MAIN_RESOURCES_CONFIG_YML

cat > "src/main/resources/plugin.yml" << 'HEREDOC_SRC_MAIN_RESOURCES_PLUGIN_YML'
name: RankStealSMP
version: '${project.version}'
main: me.ranksteal.RankStealPlugin
api-version: '1.21'
description: Premium rank-stealing SMP plugin
authors: [ RankSteal ]
website: https://github.com/ranksteal/RankStealSMP
softdepend: [ PlaceholderAPI ]

commands:
  rank:
    description: View your current rank
    usage: /rank [player]
    aliases: [ r ]
  topranks:
    description: View top ranked players
    usage: /topranks [page]
    aliases: [ top, leaderboard, lb ]
  setrank:
    description: Set a player's rank (Admin)
    usage: /setrank <player> <rank>
    permission: ranksteal.admin.setrank
  rankreload:
    description: Reload plugin configuration
    usage: /rankreload
    permission: ranksteal.admin.reload

permissions:
  ranksteal.admin:
    description: Full admin access
    default: op
    children:
      ranksteal.admin.setrank: true
      ranksteal.admin.reload: true
  ranksteal.admin.setrank:
    description: Set any player's rank
    default: op
  ranksteal.admin.reload:
    description: Reload plugin config
    default: op
  ranksteal.rank:
    description: View rank info
    default: true
  ranksteal.topranks:
    description: View leaderboard
    default: true

HEREDOC_SRC_MAIN_RESOURCES_PLUGIN_YML

echo "All files created! Run: mvn clean package"
