import nfldb
import sys

db = nfldb.connect()

player_objs = dict()
player_stats = dict()

multipliers = dict()

multipliers["passing_yds"] = 0.05
# multipliers["passing_yds"] = 0.04
multipliers["passing_int"] = -2

multipliers["passing_tds"] = 6
# multipliers["passing_tds"] = 4
multipliers["passing_twoptm"] = 2


multipliers["rushing_yds"] = 0.1
multipliers["rushing_twoptm"] = 2

multipliers["rushing_tds"] = 6

multipliers["receiving_yds"] = 0.1
multipliers["receiving_tds"] = 6

multipliers["receiving_rec"] = 1
# multipliers["receiving_rec"] = 0.25
multipliers["receiving_twoptm"] = 2


multipliers["kickret_yds"] = 0.03
multipliers["kickret_tds"] = 6
multipliers["fumbles_rec_tds"] = 6
multipliers["fumbles_lost"] = -1
# fixme multipliers["FRTD"] = 6

multipliers["puntret_yds"] = 0.03
multipliers["puntret_tds"] = -1
multipliers["fumbles_tot"] = -1
# fixme multipliers["INTTD"] = 6
# fixme multipliers["BLKKRTD"] = 6

# fixme kicking
# fixme defense 

valid_positions = nfldb.Enums.player_pos.QB, nfldb.Enums.player_pos.WR, nfldb.Enums.player_pos.RB

q = nfldb.Query(db)
for player in q.game(season_year=2013, season_type='Regular').as_players():

	player_objs[player.player_id] = player

	if player.position not in valid_positions:
		continue

	if player.position not in player_stats:
		player_stats[player.position] = dict()

	player_stats[player.position][player.player_id] = 0
	for x in range(1, 18):
		q = nfldb.Query(db)
		q.game(season_year=2013, season_type='Regular')
	
		game_stats = dict()
	
		for pp in q.player(player_id = player.player_id).game(week = x).as_play_players():
			for f in pp.fields:
				if f not in game_stats: 
					game_stats[f] = 0
				game_stats[f] += getattr(pp, f, 0)
	
		game_stat = 0
		for f in game_stats:
			points = round(game_stats[f] * multipliers.get(f, 0), 1)
			# print "stat: ", f, game_stats[f], points
			game_stat += points
	
		# print "game: ", game_stat
		player_stats[player.position][player.player_id] += game_stat

for f in player_stats:
	print f
	for t in sorted(player_stats[f].items(), key=lambda x: x[1], reverse = True)[0:10]:
		print player_objs[t[0]], t[1]

