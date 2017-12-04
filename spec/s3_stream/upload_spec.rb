require 'spec_helper'

RSpec.describe S3Stream::Upload do
  subject { described_class.instance client, options }

  let(:client) do
    Fog::Storage.new(:provider => 'AWS',
                     :aws_access_key_id => 'key',
                     :aws_secret_access_key => 'secret')
  end

  let(:options) do
    { :maxsize => 10,
      :bucket => 'fake-bucket',
      :filepath => 'some/path',
      :filename => 'novel.txt.gz' }
  end

  let(:my_novel) do
    "hello world\nhello world"
  end

  let(:upload) { double 'upload', :upload_id => 'some uid' }

  before do
    Fog.mock!
    allow_any_instance_of(S3Stream::Upload::OutputBuffer)
      .to receive(:minimum_max_size)
      .and_return 0
    client.put_bucket 'fake-bucket'

    subject.io.writer.mtime = Time.parse('1-1-2001').utc
  end

  feature 'streaming gzip data to S3' do
    it 'uploads in parts' do
      expect(client).to receive(:initiate_multipart_upload).with(
        'fake-bucket',
        'some/path',
        { 'x-amz-server-side-encryption' => 'AES256',
          'Content-Type' => 'application/gzip',
          'Content-Disposition' => 'attachment; filename="novel.txt.gz"' }
      ).and_call_original
      expect(client).to receive(:upload_part).with(
        'fake-bucket',
        'some/path',
        subject.output.upload_id,
        1,
        "\u001F\x8B\b\u0000\x80\xC8O:\u0000\u0003",
        {}
      ).and_call_original
      expect(client).to receive(:upload_part).with(
        'fake-bucket',
        'some/path',
        subject.output.upload_id,
        2,
        "\xCBH\xCD\xC9\xC9W(\xCF/\xCAI\xE1\xCA@\xB0\u0001\xA2\xFD\xE4\u0018\u0017\u0000\u0000\u0000",
        {}
      ).and_call_original
      expect(client).to receive(:complete_multipart_upload).with(
        'fake-bucket',
        'some/path',
        subject.output.upload_id,
        %w(1 2) # ETags of the parts, in order by part number
      ).and_call_original

      subject.zipstream(my_novel.each_line)
    end

    it 'uploads whole data correctly' do
      subject.zipstream(my_novel.each_line)
      object = client.get_object('fake-bucket', 'some/path')
      raw = object.data[:body]

      text = Zlib::GzipReader.new(StringIO.new(raw)).read

      expect(text).to eq my_novel
    end
  end
end
