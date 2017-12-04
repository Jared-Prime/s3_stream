module S3Stream
  class Configuration
    class << self
      attr_accessor :aws_access_key_id, :aws_secret_access_key,
        :aws_region_name, :uses_aws_iam_profile, :aws_bucket_name

      def storage_settings
        { :provider => 'AWS',
          :aws_access_key_id => aws_secret_access_key,
          :aws_secret_access_key => aws_secret_access_key,
          :region => aws_region_name,
          :use_iam_profile => uses_aws_iam_profile }.reject { |_, v| v.blank? }
      end
    end
  end
end