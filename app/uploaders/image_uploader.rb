class ImageUploader < CarrierWave::Uploader::Base
  # Include RMagick or MiniMagick support:
  include CarrierWave::RMagick

  # Choose what kind of storage to use for this uploader:
  storage :file

  # 画像の上限を100pxにする
  process :resize_to_limit => [100, 100]
  version :thumb do
    process :resize_to_limit => [200, 200]
  end
    # 保存形式をJPGにする
  process :convert => 'jpg'
  def filename
    super.chomp(File.extname(super)) + '.jpg' if original_filename.present?
  end

  # Choose what kind of storage to use for this uploader:

  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end


  def default_url(*args)
    ActionController::Base.helpers.asset_path("fallback/" + [version_name, "bg-md.jpg"].compact.join('_'))
  end
  # Process files as they are uploaded:
  # process scale: [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process resize_to_fit: [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_whitelist
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
end
