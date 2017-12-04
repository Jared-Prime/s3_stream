module S3Stream
  module Download
    def self.instance(uid, filename, _s3_model = nil)
      Instance.new(
        fog_storage,
        :uid => uid,
        :bucket => default_bucket,
        :filename => filename
      )
    end

    def self.fog_storage
      if APP_CONFIG[:dragonfly_access_key_id].present?
        Fog::Storage.new(
          :provider => 'AWS',
          :aws_access_key_id => APP_CONFIG[:dragonfly_access_key_id],
          :aws_secret_access_key => APP_CONFIG[:dragonfly_secret_access_key],
          :region => APP_CONFIG[:dragonfly_region]
        )
      else
        Fog::Storage.new(
          :provider => 'AWS',
          :use_iam_profile => APP_CONFIG[:dragonfly_use_iam_profile],
          :region => APP_CONFIG[:dragonfly_region]
        )
      end
    end
    private_class_method :fog_storage

    def self.default_bucket
      APP_CONFIG[:dragonfly_bucket_name]
    end
    private_class_method :default_bucket

    class Instance
      attr_reader :entity, :io

      def initialize(client, uid:, bucket:, **options)
        @entity = S3Stream::Entity.new(uid, options.merge(:client => client, :bucket => bucket))
        @io = S3Stream::Download::OutputWriter.new(entity)
      end

      delegate :stream_file, :to => :io
    end
  end
end
