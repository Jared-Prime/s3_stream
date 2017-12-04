require 'spec_helper'

RSpec.describe S3Stream::Upload::InputWriter do
  subject { described_class.new buffer }

  let(:buffer) { instance_double S3Stream::Upload::OutputBuffer }

  before do
    subject.writer.mtime = Time.parse('1-1-2001').utc
  end

  describe '#write' do
    it 'writes gzipped data to the buffer' do
      expect(buffer)
        .to receive(:write)
        .with("\x1F\x8B\b\x00\x80\xC8O:\x00\x03".force_encoding('ASCII-8BIT'))

      subject.write 'hello world'
    end
  end

  describe '#finish' do
    before do
      allow(buffer).to receive(:write)
      allow(buffer).to receive(:finish)
    end

    it 'writes final gzip stream to the buffer' do
      expect(buffer)
        .to receive(:write)
        .with "\x1F\x8B\b\x00\x80\xC8O:\x00\x03\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00".force_encoding('ASCII-8BIT')

      subject.finish
    end

    it 'closes the gzip writer' do
      subject.finish
      expect(subject.writer).to be_closed
    end
  end
end
