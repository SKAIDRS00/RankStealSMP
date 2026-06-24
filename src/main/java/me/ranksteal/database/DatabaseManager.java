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
