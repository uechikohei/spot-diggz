if defined?(AssetSync)
  AssetSync.configure do |config|
    config.enabled = false if Rails.env.test? #テスト環境では、ローカルディレクトリを参照
    config.fog_provider           = 'AWS'
    Fog.credentials               = { path_style: true }
    config.fog_directory          = 'sss-my-public'
    config.aws_access_key_id      = ENV['AWS_ACCESS_KEY_ID']
    config.aws_secret_access_key  = ENV['AWS_SECRET_ACCESS_KEY']
    config.fog_region             = 'ap-northeast-1'
    config.existing_remote_files  = 'delete'
    ##gzipとmanifestを指定すると、manifest.jsonしかアップされない
    #config.gzip_compression       = true
    #config.manifest               = true

    config.add_local_file_paths do
      Dir.chdir(Rails.root.join('public')) do
        Dir[File.join(Webpacker.config.public_output_path, '/**/**')]
      end
    end
  end
end
