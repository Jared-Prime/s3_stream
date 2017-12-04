module S3Stream
  module Upload
    class OutputBuffer
      attr_reader :buffer, :destination, :maxsize

      MB = 1024**2
      GB = 1024**3

      def initialize(destination, **options)
        @buffer = StringIO.new
        @destination = destination
        @maxsize = options.fetch(:maxsize, default_max_size)

        raise(ArgumentError, 'maxsize must be at least 5 MB in size') if maxsize < minimum_max_size
      end

      def write(data)
        buffer << data

        autoflush
        self
      end
      alias << write

      def finish
        flush unless size.zero?
        destination.finish
        destination
      end

      def flush
        buffer.rewind
        destination << buffer.read

        @buffer = StringIO.new
      end

      delegate :size, :to => :buffer

      private

      # Upload parts must be at least 5MB per the AWS upload part API
      # http://docs.aws.amazon.com/AmazonS3/latest/API/mpUploadUploadPart.html
      def minimum_max_size
        5 * MB
      end

      def default_max_size
        100 * MB
      end

      def autoflush
        flush if buffer.size >= maxsize
      end
    end
  end
end
