class PlayersController < ApplicationController
  before_action :set_player, only: [:update]

  # GET /players
  # GET /players.json
  def index
    @players = Player.all
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
