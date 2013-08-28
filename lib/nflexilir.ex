defmodule Nflexilir do

  def schedule do
    IO.puts "[start] schedule"
    {:ok, json} = JSON.decode(File.read!("lib/data.json"))
    IO.puts "[end] schedule"
    Enum.filter(json, fn(x) -> 
      Dict.fetch!(x, "season") == 2012 && Dict.fetch!(x, "season_type") == "REG"
    end)
  end

  def json_objects do
    schedule = Nflexilir.schedule
    IO.puts "[schedule] "
    IO.inspect Enum.count(schedule)
    Enum.map(Enum.with_index(schedule), fn(pair) ->
      {x, i} = pair
      eid = Dict.fetch!(x, "eid")
      filename = "lib/gamecenter-json.json/#{eid}.json"
      {:ok, json} = JSON.decode(File.read!(filename))

      IO.puts "[i] "
      IO.inspect i
      Dict.fetch!(json, eid)
    end)
  end

  def merge(d1, d2) do
    Dict.merge(d1, d2, fn(_k, v1, v2) ->                                                
      Dict.merge(v1, v2, fn(_k2, v3, v4) ->
        if (_k2 == "name" || _k2 == "clubcode" || _k2 == "playerName") do
          if (v3 == v4) do
            v3
          else 
            IO.inspect(v3 <> " is not equal to " <> v4)
            v3
          end
        else
          v3 + v4
        end
      end)
    end)
  end

  def merge_away_home_and_attr(f, attr) do
    Enum.reduce(f, HashDict.new(), fn(x, acc1) ->
      if (attr == "kicking") do
        # {"00-0020305": {"att": 24}}
        drives = Dict.fetch!(x, "drives")
        drives_hash = Enum.reduce(Dict.keys(drives), HashDict.new(), fn(drive_key, acc2) ->
          if (drive_key == "crntdrv") do
            acc2
          else
            plays = Dict.fetch!(Dict.fetch!(drives, drive_key), "plays")
            plays_hash = Enum.reduce(Dict.keys(plays), HashDict.new(), fn(play_key, acc3) ->
              play_hash = Dict.fetch!(plays, play_key)
              if (Dict.fetch!(play_hash, "note") == "FG") do
                players_hash = Dict.fetch!(play_hash, "players")
                player_keys = Dict.keys(players_hash)
                kickers = Enum.filter(player_keys, fn(x) -> 
                  kicker_array = Dict.fetch!(players_hash, x)
                  Enum.any?(kicker_array, fn(y) -> Dict.fetch!(y, "statId") == 70 end)
                end)
                if (Enum.count(kickers) != 1) do
                  IO.inspect players_hash
                  raise "More than one player participated in a field goal?"
                end
                player_id = Enum.fetch!(kickers, 0)
                players_array = Dict.fetch!(players_hash, player_id)
                if (Enum.count(kickers) != 1) do
                  raise "More than one play in a field goal?"
                end
                kicking_stats = Enum.fetch!(players_array, 0)
                yds = Dict.fetch!(kicking_stats, "yards")
                converted_stats = HashDict.new([{"fg0", 0}, {"fg40", 0}, {"fg50", 0}, {"playerName", Dict.fetch!(kicking_stats, "playerName")}])
                key = cond do
                  yds < 40 -> "fg0"
                  yds < 50 -> "fg40"
                  true -> "fg50"
                end
                converted_stats = Dict.put(converted_stats, key, 1)
                Nflexilir.merge(acc3, HashDict.new([{player_id, converted_stats}]))
              else
                acc3
              end
            end)
            Nflexilir.merge(acc2, plays_hash)
          end
        end)
        Nflexilir.merge(acc1, drives_hash)
      else 
        places = Enum.reduce(["home", "away"], HashDict.new(), fn(t, acc2) ->
          case HashDict.fetch(HashDict.fetch!(HashDict.fetch!(x, t), "stats"), attr) do
            {:ok, attr_hash} -> 
              if (attr == "puntret" || attr == "kickret") do
                attr_hash = Enum.reduce(Dict.keys(attr_hash), HashDict.new, fn(player, pacc) ->
                  stats = Dict.fetch!(attr_hash, player)
                  {average, stats} = Dict.pop(stats, "avg")
                  {ret, stats} = Dict.pop(stats, "ret")
                  stats = Dict.put(stats, "tot", average * ret)
                  Dict.put(pacc, player, stats)
                end)
              end
              Nflexilir.merge(acc2, attr_hash)
            :error -> Nflexilir.merge(acc2, HashDict.new)
          end
        end)
        Nflexilir.merge(acc1, places)
      end
    end)
  end

  def merge_all_stats(f) do
    Enum.reduce(["passing", "rushing", "receiving", "kickret", "puntret", "fumbles", "kicking"], HashDict.new(), fn(stat, acc) ->
      stats = Nflexilir.merge_away_home_and_attr(f, stat)
      player_stats = Enum.reduce(Dict.keys(stats), HashDict.new, fn(player, acc2) ->
        stat_hash = Dict.fetch!(stats, player)

        Dict.put(acc2, player, HashDict.new([{stat, stat_hash}]))
      end)
      Dict.merge(acc, player_stats, fn(_k1, v1, v2) -> 
        Dict.merge(v1, v2, fn(_k2, _v1, _v2) -> 
          raise "should not happen " <> _k1 <> " " <> _k2
        end)
      end)
    end)
  end

  def get_player_stats(f) do
    stats = Nflexilir.merge_all_stats(f)

    point_methods = [
      {
        "passing", fn(h) ->
          Dict.fetch!(h, "yds") * 0.04 + 
          Dict.fetch!(h, "ints") * -2 + 
          Dict.fetch!(h, "tds") * 4 + 
          Dict.fetch!(h, "twoptm") * 2
        end
      }, {
        "rushing", fn(h) ->
          Dict.fetch!(h, "yds") * 0.1 + 
          Dict.fetch!(h, "twoptm") * 2 + 
          Dict.fetch!(h, "tds") * 6
        end
      }, {
        "receiving", fn(h) ->
          Dict.fetch!(h, "yds") * 0.1 + 
          Dict.fetch!(h, "tds") * 6 + 
          Dict.fetch!(h, "rec") * 0.25 + 
          Dict.fetch!(h, "twoptm") * 2
        end
      }, {
        "kickret", fn(h) ->
          Dict.fetch!(h, "tot") * 0.03 + 
          Dict.fetch!(h, "tds") * 6
        end
      }, {
        "puntret", fn(h) ->
          Dict.fetch!(h, "tot") * 0.03 + 
          Dict.fetch!(h, "tds") * 6
        end
      }, {
        "fumbles", fn(h) ->
          # Fumble Recovered for TD (FTD)
          Dict.fetch!(h, "lost") * -1 +
          # Fumble Return TD (FRTD)
          Dict.fetch!(h, "tot") * -1
        end
      }, {
        "kicking", fn(h) ->
          Dict.fetch!(h, "fg0") * 3 +
          Dict.fetch!(h, "fg40") * 4 + 
          Dict.fetch!(h, "fg50") * 5
        end
      }
    ]

    points = Enum.map(Dict.keys(stats), fn(player) ->
      player_dict = Dict.fetch!(stats, player)

      projection_dict = Enum.reduce(point_methods, HashDict.new(), fn(meth, acc) ->
        {k, method} = meth
        value = case Dict.fetch(player_dict, k) do
          {:ok, h} -> method.(h)
          :error -> 0
        end
        Dict.put(acc, k, value)
      end)

      total = Enum.reduce(Dict.keys(projection_dict), 0, fn(x, acc) ->
        acc + Dict.fetch!(projection_dict, x) 
      end)
      projection_dict = HashDict.put(projection_dict, "total", total)

      Dict.put(player_dict, "projection", projection_dict)
    end)
    sort_players_by_key(points, "total")
  end
  
  def sort_players_by_key(p, key) do
    Enum.sort(p, fn(a, b) -> 
      atotal = Dict.fetch!(Dict.fetch!(a, "projection"), key)
      btotal = Dict.fetch!(Dict.fetch!(b, "projection"), key)
      atotal > btotal
    end)
  end

end
