class Map < ApplicationRecord
  geocoded_by :address
  after_validation :geocode, if: :address_changed?

  def self.search(address)
    return Map.all unless address
    Map.where(['content LIKE ?', "%#{address}%"])
  end

end
