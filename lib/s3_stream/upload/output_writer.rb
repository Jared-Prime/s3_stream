module S3Stream
  module Upload
    class OutputWriter
      attr_reader :entity, :parts, :part_number, :logger

      def initialize(entity, logger: Logger.new(STDOUT))
        @entity = entity
        @logger = logger
        @part_number = 1
        @parts = {}
      end

      def upload_id
        @upload_id ||= start.data.dig(:body, 'UploadId')
      end

      def start
        return @upload_id if defined? @upload_id

        with_logging('upload.initiate') do
          entity.put(:initiate_multipart_upload,
                     { 'x-amz-server-side-encryption' => 'AES256',
                       'Content-Type' => 'application/gzip',
                       'Content-Disposition' => "attachment; filename=\"#{entity.filename}\"" })
        end
      end

      def write(chunk)
        with_logging('upload.part') do
          res = entity.put(:upload_part,
                           upload_id,
                           part_number,
                           chunk,
                           {})

          parts[part_number] = res.data.dig(:headers, 'ETag')

          res
        end

        @part_number += 1
      end
      alias << write

      def finish
        with_logging('upload.complete') do
          entity.put(:complete_multipart_upload,
                     upload_id,
                     parts.values)
        end
      end

      def abort_with_exception(exception)
        abort!

        message = if exception.respond_to?(:message)
                    exception.message
                  else
                    exception
                  end

        logger.error(:filename => entity.uid,
                     :parts_count => part_number,
                     :action => 'upload.error',
                     :status => 'FAIL',
                     :error => "Upload aborted due to: #{message}")
      end

      def abort!
        with_logging('upload.abort') do
          entity.put(:abort_multipart_upload, upload_id)
        end
      end

      private

      def with_logging(action)
        result = yield

        logger.info(:filename => entity.uid,
                    :parts_count => part_number,
                    :action => action,
                    :status => 'OK',
                    :result => result.data)

        result
      rescue => ex
        abort_with_exception(ex)

        raise ex
      end
    end
  end
end
