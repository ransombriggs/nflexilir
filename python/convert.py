import nflgame.schedule
import json

def second(pair):
    return pair[1]

games = map(second, nflgame.schedule.games)
with open('lib/data.json', 'w') as outfile:
      json.dump(games, outfile, indent=4)

