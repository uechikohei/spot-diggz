class LikesController < ApplicationController

  def create
    @like = current_user.likes.create(map_id: params[:map_id])
    respond_to do |format|
      if @like.save
        format.html { redirect_back(fallback_location: root_path) }
        format.js
      end
    end
  end

  def destroy
    @like = Like.find_by(map_id: params[:map_id], user_id: current_user.id)
    @like.destroy
    redirect_back(fallback_location: root_path)
  end

end
