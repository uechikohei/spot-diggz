class Map < ApplicationRecord
  mount_uploader :picture, PictureUploader
  reverse_geocoded_by :latitude, :longitude
  after_validation :reverse_geocode
  validates :title, length: { maximum: 20}
  validates :content, length: { maximum: 300}

  def self.search(address)
    return Map.all unless address
    Map.where(['content LIKE ?', "%#{address}%"])
  end

end