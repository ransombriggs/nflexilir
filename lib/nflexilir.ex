defmodule Nflexilir do
  def json_files do
    json_dir = "lib/gamecenter-json.json"
    {:ok, files} = File.ls(json_dir)
    Enum.filter(files, fn(x) -> String.starts_with?(x, "2013") end)
  end

  def json_objects do
    Enum.map(json_files, fn(x) ->
      filename = "lib/gamecenter-json.json/#{x}"
      {:ok, json} = JSON.decode(File.read!(filename))

      key = Enum.fetch!(Regex.run(%r/^([0-9]+)\.json$/, x), 1)
      Dict.fetch!(json, key)
    end)
  end
end
