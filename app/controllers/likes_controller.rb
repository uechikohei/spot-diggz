class LikesController < ApplicationController
  before_action :set_post

  def create
    @like = current_user.likes.create(map_id: params[:map_id])
    @like.save
    @post = @like.post
  end

  def destroy
    @like = Like.find_by(map_id: params[:map_id], user_id: current_user.id)
    @post = @like.post
    @like.destroy
    @post.reload
  end

  def set_post
    @post = Map.find(params[:map_id])
  end

end
