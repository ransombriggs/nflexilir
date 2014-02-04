import nfldb
import sys

db = nfldb.connect()
q = nfldb.Query(db)
for player in q.player(full_name = sys.argv[1]).as_players():
	print player, player.player_id

