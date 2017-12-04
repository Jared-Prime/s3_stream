require 'spec_helper'

RSpec.describe S3Stream::Download::OutputWriter do
  subject { described_class.new entity }

  let(:entity) do
    instance_double S3Stream::Entity,
                    :content_type => 'text/plain',
                    :content_disposition => 'attachment; filename="message.txt"'
  end

  let(:stream) do
    instance_double IO, :close => true
  end

  let(:headers) { {} }

  before do
    allow(stream)
      .to receive(:write)
    allow(entity)
      .to receive(:get)
      .and_yield('Line 1')
      .and_yield('Line 2')
  end

  describe '#stream_file' do
    it 'writes to the stream' do
      expect(stream).to receive(:write).with('Line 1')
      expect(stream).to receive(:write).with('Line 2')

      subject.stream_file(headers, stream)
    end

    it 'sets headers' do
      subject.stream_file(headers, stream)

      expect(headers['Content-Disposition'])
        .to eq('attachment; filename="message.txt"')
      expect(headers['Content-Type']).to eq 'text/plain'
    end
  end
end
