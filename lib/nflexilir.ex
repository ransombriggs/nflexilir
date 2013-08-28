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
        if (_k2 == "name") do
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
      score_summary = Dict.fetch!(x, "scrsummary")
      kicking_dict = Enum.reduce(Dict.keys(score_summary), HashDict.new, fn(scr, kacc) -> 
        #IO.inspect(Dict.fetch!(score_summary, scr))
        kacc
      end)
      Nflexilir.merge(acc1, Nflexilir.merge(places, kicking_dict))
    end)
  end

  def merge_all_stats(f) do
    Enum.reduce(["passing", "rushing", "receiving", "kickret", "puntret", "fumbles"], HashDict.new(), fn(stat, acc) ->
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

    Enum.sort(points, fn(a, b) -> 
      atotal = Dict.fetch!(Dict.fetch!(a, "projection"), "total")
      btotal = Dict.fetch!(Dict.fetch!(b, "projection"), "total")
      atotal > btotal
    end)
  end

end
