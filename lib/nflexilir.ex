defmodule Nflexilir do

  def schedule do
    {:ok, json} = JSON.decode(File.read!("lib/data.json"))
    Enum.filter(json, fn(x) -> 
      Dict.fetch!(x, "year") == 2012 && Dict.fetch!(x, "season_type") == "REG"
    end)
  end

  def json_objects do
    Enum.map(Nflexilir.schedule, fn(x) ->
      eid = Dict.fetch!(x, "eid")
      filename = "lib/gamecenter-json.json/#{eid}.json"
      {:ok, json} = JSON.decode(File.read!(filename))

      Dict.fetch!(json, eid)
    end)
  end

  def get_player_passing(f) do
    fnmerge = fn(d1, d2) -> 
      Dict.merge(d1, d2, fn(_k, v1, v2) ->                                                
        Dict.merge(v1, v2, fn(_k2, v3, v4) ->
          if (_k2 == "name") do
            if (v3 == v4) do
              v3
            else 
              raise v3 <> " is not equal to " <> v4
            end
          else
            v3 + v4
          end
        end)
      end)
    end
    passing = Enum.reduce(f, HashDict.new(), fn(x, acc1) ->
      places = Enum.reduce(["home", "away"], HashDict.new(), fn(t, acc2) ->
        passing = HashDict.fetch!(HashDict.fetch!(HashDict.fetch!(x, t), "stats"), "passing")
        fnmerge.(acc2, passing)
      end)
      fnmerge.(acc1, places)
    end)

    passing_pts = fn(h) -> 
      Dict.fetch!(h, "yds") * 0.04 + 
        Dict.fetch!(h, "ints") * -2 + 
        Dict.fetch!(h, "tds") * 4 + 
        Dict.fetch!(h, "twoptm") * 2
    end
    Enum.map(Enum.sort(Dict.keys(passing), fn(a, b) -> 
      passing_pts.(Dict.fetch!(passing, a)) > passing_pts.(Dict.fetch!(passing, b))
    end), fn(player) ->
      Dict.fetch!(passing, player)
    end)
  end

end
