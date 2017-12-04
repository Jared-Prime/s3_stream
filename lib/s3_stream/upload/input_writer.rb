module S3Stream
  module Upload
    class InputWriter
      attr_reader :writer, :buffer

      def initialize(buffer)
        @buffer = buffer
        @writer = Zlib::GzipWriter.new(buffer)
      end

      delegate :write, :to => :writer
      delegate :<<, :to => :writer

      def finish
        writer.finish
        buffer.finish
      end
    end
  end
end
