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
    drafted_players_list = Player.includes(:team).where(claimed_by: 1).order("claim_time asc")
    drafted_players_size = drafted_players_list.size

    @bye_weeks = {}
    ::PlayersController.roster.each do |(k,v)|
      if (k != "WR/TE")
        @bye_weeks[k] = Set.new
      end
    end

    drafted_players_list.each do |player|
      @bye_weeks[player.position] << player.team.bye
    end

    @starting_players = []
    @benched_players  = []

    starter_positions = []
    bench_positions = []

    ::PlayersController.roster.each do |(key,value)|
      count = 0
      (start_limit, _) = value
      drafted_players_list = drafted_players_list.reduce([]) {|dacc, player|
        if (match(key, player.position))
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
        if (match(key, player.position))
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

    unless ['proj', 'stats'].include?(order)
      raise "bad order"
    end

    all_available_players = Player.includes(:team).where(claimed_by: nil).order("#{order} desc")
    @highest_ranked = all_available_players
  
    starter_positions_dup = Set.new(starter_positions)
    starter_positions_dup.delete("D/ST")
    starter_positions_dup.delete("K")
    if (starter_positions_dup.empty?)
      @exclude_kicker_defense = select_players(all_available_players, bench_positions)[0..10]
    else
      @exclude_kicker_defense = []
    end

    @available_players = select_players(all_available_players, valid_positions)[0..10]

    @removed_players = Player.includes(:team).where(claimed_by: 0).order("claim_time asc")
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
    def match(key, position)
      position == key || (key == "WR/TE" && (["WR", "TE"].include?(position)))
    end

    def select_players(players, positions)
      players.reduce([]) {|acc, player|
        if (positions.find {|position| match(position, player.position)}) 
          acc << player
        end
        acc
      }
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_player
      @player = Player.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def player_params
      params[:player]
    end
end
