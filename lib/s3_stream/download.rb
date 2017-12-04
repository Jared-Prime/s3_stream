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
      Fog::Storage.new(S3Stream::Configuration.storage_settings)
    end
    private_class_method :fog_storage

    def self.default_bucket
      S3Stream::Configuration.aws_bucket_name
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
