import nflgame.schedule
import json

def second(pair):
    game = pair[1]
    game["season"] = pair[0][0]
    return game

games = map(second, nflgame.schedule.games)
with open('lib/data.json', 'w') as outfile:
      json.dump(games, outfile, indent=4)

