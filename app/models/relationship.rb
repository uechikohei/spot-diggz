class Relationship < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  def follow
    current_user.follow(params[:id])
    redirect_to root_path
  end
  def unfollow
    current_user.unfollow(params[:id])
    redirect_to root_path
  end
end
