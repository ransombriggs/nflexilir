package controllers;

import org.codehaus.jackson.JsonFactory;
import org.codehaus.jackson.JsonParser;
import org.codehaus.jackson.map.ObjectMapper;
import org.codehaus.jackson.type.JavaType;
import play.*;
import play.mvc.*;

import java.io.File;
import java.io.IOException;
import java.util.*;

import models.*;

public class Application extends Controller {

    public static void index() {
        List<Player> allPlayers = Player.find("proj > 0").fetch();
        List<Player> draftedPlayers = new ArrayList<Player>(allPlayers.size());
        List<Player> availablePlayers = new ArrayList<Player>(allPlayers.size());

        for (Player player: allPlayers) {
            if (player.claimed_by == null) {
                availablePlayers.add(player);
            } else if (player.claimed_by.equals(1L)) {
                draftedPlayers.add(player);
            }
        }

        List<Player> sortedByRank = new ArrayList<Player>(availablePlayers);
        Collections.sort(sortedByRank, new Comparator<Player>() {
            @Override
            public int compare(Player o1, Player o2) {
                return o1.rank.compareTo(o2.rank);
            }
        });

        List<Player> sortedByProj = new ArrayList<Player>(availablePlayers);
        Collections.sort(sortedByProj, new Comparator<Player>() {
            @Override
            public int compare(Player o1, Player o2) {
                return o2.proj.compareTo(o1.proj);
            }
        });

        List<Player> availableQuarterBacks = new ArrayList<Player>(availablePlayers.size());
        List<Player> availableRunningBacks = new ArrayList<Player>(availablePlayers.size());
        List<Player> availableWideReceivers = new ArrayList<Player>(availablePlayers.size());
        List<Player> availableTightEnds = new ArrayList<Player>(availablePlayers.size());
        List<Player> availableDefense = new ArrayList<Player>(availablePlayers.size());
        List<Player> availableKickers = new ArrayList<Player>(availablePlayers.size());

        for (Player player: sortedByProj) {
            if (player.position.equals("QB")) {
                availableQuarterBacks.add(player);
            } else if (player.position.equals("RB")) {
                availableRunningBacks.add(player);
            } else if (player.position.equals("WR")) {
                availableWideReceivers.add(player);
            } else if (player.position.equals("TE")) {
                availableTightEnds.add(player);
            } else if (player.position.equals("D/ST")) {
                availableDefense.add(player);
            } else if (player.position.equals("K")) {
                availableKickers.add(player);
            } else {
                throw new IllegalArgumentException(player.position);
            }
        }

        render(sortedByRank, sortedByProj, availableQuarterBacks, availableRunningBacks, availableWideReceivers, availableTightEnds, availableDefense, availableKickers, draftedPlayers);
    }

    public static void update(Long player, String draft, String remove) {
        Player playerModel = Player.findById(player);
        if (draft != null) {
            playerModel.claimed_by = 1L;
        } else if (remove != null) {
            playerModel.claimed_by = 0L;
        }
        playerModel._save();
        index();
    }

    public static void load() throws IOException {
        ObjectMapper mapper = new ObjectMapper();
        JavaType javaType = mapper.getTypeFactory().constructCollectionType(List.class, Player.class);
        List<Player> list = mapper.readValue(new File("/home/rbriggs/git/nflexilir/draft/cache/players.json"), javaType);
        for (Player player: list) {
            player._save();
        }
        renderJSON(list);
    }

}