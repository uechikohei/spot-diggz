Geocoder.configure(
  lookup: :google,
  language: :ja,
  api_key: Rails.application.credentials.google_map_api[:key],
  units: :km
)
