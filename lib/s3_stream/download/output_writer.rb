module S3Stream
  module Download
    class OutputWriter
      attr_reader :entity

      def initialize(entity)
        @entity = entity
      end

      def stream_file(headers, stream)
        headers['Content-Type'] = entity.content_type
        headers['Content-Disposition'] = entity.content_disposition || default_content_disposition(entity)

        entity.get { |data| stream.write data }
      rescue ActionController::Live::ClientDisconnected, IOError
        # If the client cancels the download, or it fails client side for some
        # reason ActionController::Life throws, handle it
        Fluentd.logger.info(
          :tag => 's3.streamer',
          :message => "zip file download failure #{entity.filename} uid: #{entity.uid}",
          :trace_location => 'conduit'
        )
      rescue Excon::Error::NotFound => ex
        Fluentd.logger.error(
          :tag => 's3.streamer',
          :message => "unknown uid requested for file download #{entity.filename} uid: #{entity.uid}",
          :trace_location => 'conduit'
        )

        raise ex
      ensure
        stream.close
      end

      def default_content_disposition(entity)
        "attachment; filename=\"#{entity.filename}\""
      end
    end
  end
end
