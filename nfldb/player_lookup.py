import nfldb
import sys

db = nfldb.connect()
q = nfldb.Query(db)
player_name = sys.argv[1]
players = q.player(full_name = player_name).as_players()
if (len(players) == 0):
	print "Could not find " + player_name
elif (len(players) == 1):
	print "Success"
	player = players[0]
	p = open('players.txt', 'a')
	p.write(player.player_id + " # " + player_name + "\n")
	p.close()
else:
	print "Multiple player matches " + player_name
	for player in q.player(full_name = sys.argv[1]).as_players():
		print player.player_id + " # " + str(player)

