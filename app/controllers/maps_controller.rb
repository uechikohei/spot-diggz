class MapsController < ApplicationController
  # google map apiを取得する
  before_action :set_map, only: %i[show edit update destroy]
  before_action :authenticate_user!, only: %i[new create destroy]

  # GET /maps
  # GET /maps.json
  def index
    @maps = Map.all
  end

  def search
    @test = Map.search(params[:address])
  end

  # GET /maps/1
  # GET /maps/1.json
  def show
    @map = Map.find_by(id: params[:id])
    # いいね機能追加
    @like = Like.new
    gon.lat = @map.latitude
    gon.lng = @map.longitude
  end

  # GET /maps/new
  def new
    @map = Map.new
  end

  # GET /maps/1/edit
  def edit
  end

  # POST /maps
  # POST /maps.json
  def create
    @map = Map.new(map_params)
    @map.user_id = current_user.id
    @map.save
    respond_to do |format|
      if @map.save
        format.html { redirect_to @map, notice: 'Map was successfully created.' }
        format.json { render :show, status: :created, location: @map }
      else
        format.html { render :new }
        format.json { render json: @map.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /maps/1
  # PATCH/PUT /maps/1.json
  def update
    respond_to do |format|
      if @map.update(map_params)
        format.html { redirect_to @map, notice: 'Map was successfully updated.' }
        format.json { render :show, status: :ok, location: @map }
      else
        format.html { render :edit }
        format.json { render json: @map.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /maps/1
  # DELETE /maps/1.json
  def destroy
    @map.destroy
    respond_to do |format|
      format.html { redirect_to maps_url, notice: 'Map was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_map
    @map = Map.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def map_params
    params.require(:map).permit( :latitude, :longitude, :picture, :content, :title )
  end
end