module S3Stream
  class Entity
    attr_reader :bucket, :client, :uid, :s3_root_path, :filename

    def initialize(uid, client:, bucket:, s3_root_path: nil, filename:)
      @uid = uid
      @client = client
      @bucket = bucket
      @s3_root_path = s3_root_path
      @filename = filename
    end

    def full_path
      if use_s3_root_path?
        File.join(s3_root_path, uid)
      else
        uid
      end
    end

    def content_type
      info['Content-Type']
    end

    def content_disposition
      info['Content-Disposition']
    end

    def get
      client.get_object(bucket, uid) do |object|
        yield(object) if block_given?
      end
    end

    def put(method, *args)
      client.send(method, bucket, uid, *args)
    end

    private

    def info
      @info ||= client.head_object(bucket, uid)
                      .headers
    end

    def use_s3_root_path?
      s3_root_path.present?
    end
  end
end
