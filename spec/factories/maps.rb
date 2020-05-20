FactoryBot.define do
  factory :map do
    title     { 'spec' }
    content   { 'spec content' }
    latitude  { '34.532581' }
    longitude { '135.509147' }
    picture   { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec/fixtures/test.png')) }
    association :user
  end
end