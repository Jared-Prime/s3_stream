module S3Stream
  module Upload
    def self.instance(*args)
      Instance.new(*args)
    end

    class Instance
      attr_reader :output, :buffer, :io, :entity

      def initialize(client, **options)
        @entity = S3Stream::Entity.new(
          options.fetch(:filepath),
          :client => client,
          :bucket => options[:bucket],
          :filename => options[:filename]
        )
        @output = S3Stream::Upload::OutputWriter.new(entity)
        @buffer = S3Stream::Upload::OutputBuffer.new(output, options)
        @io     = S3Stream::Upload::InputWriter.new(buffer)
      end

      # @param data [Enumerable]
      def zipstream(data)
        data.each do |datum|
          io << datum
        end

      rescue => ex
        output.abort_with_exception(ex)

        raise ex
      ensure
        io.finish
      end
    end
  end
end
