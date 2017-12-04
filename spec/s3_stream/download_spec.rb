require 'spec_helper'

RSpec.describe S3Stream::Download do
  subject do
    described_class.instance('some/s3/path/to/file', 'file.zip', anything)
  end

  before do
    allow(Fog::Storage).to receive(:new)
  end

  describe '#stream_file' do
    let(:headers) { instance_double(Hash) }
    let(:stream) { instance_double(IO) }

    # see spec/s3_stream/download/output_writer_spec for unit testing
    it 'delegates to the output writer' do
      expect(subject.io).to receive(:stream_file)

      subject.stream_file(headers, stream)
    end
  end
end
