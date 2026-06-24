package me.ranksteal.models;

import java.util.UUID;

public class PlayerData {

    private final UUID uuid;
    private String username;
    private int rankNumber;
    private int kills;
    private int deaths;
    private long lastSeen;

    public PlayerData(UUID uuid, String username, int rankNumber, int kills, int deaths, long lastSeen) {
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

