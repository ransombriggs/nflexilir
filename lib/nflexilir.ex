defmodule Nflexilir do
  def json_files do
    json_dir = "lib/gamecenter-json.json"
    {:ok, files} = File.ls(json_dir)
    Enum.filter(files, fn(x) -> String.starts_with?(x, "2013") end)
  end

  def json_content do
    Enum.map(json_files, fn(x) ->
        filename = "lib/gamecenter-json.json/#{x}"
        File.read!(filename)
    end)
  end

  def json_objects do
    Enum.map(json_content, fn(x) ->
        {:ok, json} = JSON.decode(x)
        json
    end)
  end
end
