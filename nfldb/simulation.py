import nfldb
import sys

db = nfldb.connect()

drafted_players = dict()
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

valid_positions = nfldb.Enums.player_pos.QB, nfldb.Enums.player_pos.WR, nfldb.Enums.player_pos.RB, nfldb.Enums.player_pos.TE

p = open('players.txt', 'r')
for line in p:
	player = line.partition('#')[0].rstrip()
	drafted_players[player] = 1
p.close()

q = nfldb.Query(db)
for player in q.game(season_year=2013, season_type='Regular').as_players():

	player_objs[player.player_id] = player

	if player.player_id in drafted_players:
		continue;

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

l = lambda t: (player_objs[t[0]], t[1])

sorted_player_stats = dict()

for f in player_stats:
	sorted_player_stats[f] = map(l, sorted(player_stats[f].items(), key=lambda x: x[1], reverse = True))

for f in player_stats:
	print f
	for i in range(0, 36):
		if (i % 6 == 0 and i > 0):
			print str(int(sorted_player_stats[f][0][1] - sorted_player_stats[f][i][1]))
		print sorted_player_stats[f][i][0], sorted_player_stats[f][i][1]

p = open('plateaus.dat', 'w')

for f in sorted_player_stats:
	p.write('DEPTH ')
	p.write(str(f))
	p.write('\n')

	for d in range(12, 0, -1):
		p.write(str(d))
		p.write(' ')
		p.write(str(int(sorted_player_stats[f][0][1] - sorted_player_stats[f][d][1])))
		p.write('\n')
	p.write('\n\n')
p.close()

class PickPosition:

	def __init__(self):
		self.players = dict()
		self.max_players = dict()

		for i in valid_positions:
			self.players[i] = []

		self.max_players[nfldb.Enums.player_pos.QB] = 1
		self.max_players[nfldb.Enums.player_pos.WR] = 3
		self.max_players[nfldb.Enums.player_pos.RB] = 3
		self.max_players[nfldb.Enums.player_pos.TE] = 1

	def custom_position_pick(self, player_hash, available_positions):
        	raise NotImplementedError("Please Implement this method")

	def players(self):
		return self.players

	def final_score(self):
		total = 0
		for i in self.players:
			for j in self.players[i]:
				total += j[1]
		return total

	def pick_player(self, player_hash):
		available_positions = []
		for i in self.players:
			if len(self.players[i]) < self.max_players[i]:
				available_positions.append(i)
		picked_position = self.custom_position_pick(player_hash, available_positions)
		picked_player = player_hash[picked_position].pop(0)
		self.players[picked_position].append(picked_player)
		return picked_player

class PickPositionSimple(PickPosition):

	def custom_position_pick(self, player_hash, available_positions):
		max_score = 0
		max_position = None
		for i in available_positions:
			if player_hash[i][0][1] > max_score:
				max_score = player_hash[i][0][1]
				max_position = i
		return max_position

class PickPositionPlateau(PickPosition):

	def custom_position_pick(self, player_hash, available_positions):
		max_score = 0
		max_position = None
		for i in available_positions:
			diff = player_hash[i][0][1] - player_hash[i][10][1] 
			if diff > max_score:
				max_score = diff
				max_position = i
		return max_position

sys.exit()

players = []
for i in range(0, 12):
	if i == 3:
		players.append(PickPositionPlateau())
	else:
		players.append(PickPositionSimple())

num11 = 0
for i in range(0, 7):
	if i == 2 or i % 2 == 1:
		start = 11
		end = -1
		inc = -1
	else:
		start = 0
		end = 12
		inc = 1

	for j in range(start, end, inc):
		players[j].pick_player(sorted_player_stats)

for i in range(0, 12):
	print players[i].final_score()

