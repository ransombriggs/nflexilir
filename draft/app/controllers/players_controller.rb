class PlayersController < ApplicationController
  before_action :set_player, only: [:update]

  def self.roster
    {
      "QB"    => [1, 3],
      "RB"    => [2, 4],
      "WR"    => [2, 5],
      "TE"    => [1, 3],
      "D/ST"  => [1, 3],
      "K"     => [1, 3],
      "WR/TE" => [1, nil]
    }
  end

  # GET /players
  # GET /players.json
  def index
    drafted_players_list = Player.where(claimed_by: 1).order("claim_time asc")
    drafted_players_size = drafted_players_list.size

    @starting_players = []
    @benched_players  = []

    starter_positions = []
    bench_positions = []

    match = lambda {|key, position| 
      position == key || (key == "WR/TE" && (["WR", "TE"].find{|k| k == position}))
    }

    ::PlayersController.roster.each do |(key,value)|
      count = 0
      (start_limit, _) = value
      drafted_players_list = drafted_players_list.reduce([]) {|dacc, player|
        if (match.call(key, player.position))
          count += 1
          if (count <= start_limit)
            @starting_players << player
          else
            dacc << player
          end
        else
          dacc << player
        end
        dacc
      }
      if (count < start_limit)
        starter_positions << key
      end
    end

    ::PlayersController.roster.each do |(key,value)|
      count = 0
      (start_limit, max_limit) = value
      if max_limit
        limit = max_limit - start_limit
      else
        limit = 0
      end
      drafted_players_list = drafted_players_list.reduce([]) {|dacc, player|
        if (match.call(key, player.position))
          count += 1
          if (count <= limit)
            @benched_players << player
          else
            raise "bug"
          end
        else
          dacc << player
        end
        dacc
      }
      if (count < limit)
        bench_positions << key
      elsif (count == limit)
        # we are at the max
      else
        raise "#{key}: #{count} >= #{limit}"
      end
    end

    unless (drafted_players_size == @starting_players.size + @benched_players.size)
      raise "Ug! Bug!"
    end
    if (drafted_players_list.size > 0)
      raise "Ack! bug!"
    end

    if (starter_positions.size > 0) 
      valid_positions = starter_positions
    elsif (bench_positions.size > 0) 
      valid_positions = bench_positions
    else
      valid_positions = []
    end

    order = params[:order] || 'proj'

    unless ['proj', 'stats'].find(order)
      raise "bad order"
    end

    @available_players = Player.where(claimed_by: nil).order("#{order} desc").reduce([]) {|acc, player|
      if (valid_positions.find {|position| match.call(position, player.position)}) 
        acc << player
      end
      acc
    }
    @removed_players = Player.where(claimed_by: 0).order("claim_time asc")
  end

  # PATCH/PUT /players/1
  # PATCH/PUT /players/1.json
  def update
    if params[:draft]
      @player.claimed_by = 1
    elsif params[:remove]
      @player.claimed_by = 0
    else
      raise "Expecting draft or remove"
    end
    @player.claim_time = Time.now

    @player.save!
    respond_to do |format|
      format.html { redirect_to players_url, notice: 'Player was successfully updated.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_player
      @player = Player.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def player_params
      params[:player]
    end
end
