class Map < ApplicationRecord
  mount_uploader :picture, PictureUploader
  reverse_geocoded_by :latitude, :longitude
  after_validation :reverse_geocode

  def self.search(address)
    return Map.all unless address
    Map.where(['content LIKE ?', "%#{address}%"])
  end

end