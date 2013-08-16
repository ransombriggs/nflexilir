defmodule Nflexilir do
  def json_files do
    json_dir = "/home/rbriggs/git/nflgame/nflgame/gamecenter-json.json"
    {:ok, files} = File.ls(json_dir)
    files
  end
end
