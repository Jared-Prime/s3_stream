require 'spec_helper'

RSpec.describe S3Stream::Upload::OutputWriter do
  subject { described_class.new entity, :logger => logger }

  let(:logger) { instance_double Logger }

  let(:entity) do
    S3Stream::Entity.new('some/path', :client => client, :bucket => 'fake-bucket')
  end

  let(:client) do
    Fog::Storage.new(:provider => 'AWS',
                     :aws_access_key_id => 'key',
                     :aws_secret_access_key => 'secret')
  end

  before do
    Fog.mock!
    allow(logger).to receive(:info)
    begin
      client.put_bucket 'fake-bucket'
    rescue Excon::Error::Conflict # rubocop:disable Lint/HandleExceptions
      # already exists
    end
  end

  context 'error handling' do
    describe '#handle' do
      NobodyExpectsTheSpanishInquisition = Class.new(StandardError)

      it 'aliased to #signal' do
        expect(subject).to receive(:abort!)
        expect(logger).to receive(:error)

        subject.abort_with_exception(NobodyExpectsTheSpanishInquisition)
      end
    end
  end

  context 'logging' do
    before do
      allow(client).to receive(:initiate_multipart_upload).and_call_original
      allow(client).to receive(:upload_part).and_call_original
      allow(client).to receive(:complete_multipart_upload).and_call_original
    end

    it 'logs information on starting the upload' do
      expect(logger).to receive(:info).with(hash_including(
                                              :filename => 'some/path',
                                              :parts_count => 1,
                                              :action => 'upload.initiate',
                                              :status => 'OK'
      ))

      subject.start
    end

    it 'logs information on continuing the upload' do
      expect(logger).to receive(:info).with(hash_including(
                                              :filename => 'some/path',
                                              :parts_count => 1,
                                              :action => 'upload.part',
                                              :status => 'OK'
      ))

      subject.write 'some data'
    end

    it 'logs information on completing the upload' do
      expect(logger).to receive(:info).with(hash_including(
                                              :filename => 'some/path',
                                              :parts_count => 1,
                                              :action => 'upload.complete',
                                              :status => 'OK'
      ))

      subject.finish
    end
  end

  describe '#start' do
    # http://docs.aws.amazon.com/AmazonS3/latest/API/mpUploadInitiate.html
    it 'initiates a multipart S3 upload' do
      expect(client).to receive(:initiate_multipart_upload).with(
        'fake-bucket',
        'some/path',
        { 'x-amz-server-side-encryption' => 'AES256',
          'Content-Type' => 'application/gzip',
          'Content-Disposition' => 'attachment; filename="some/path"' }
      ).and_call_original

      subject.start
    end

    it 'is idempotent' do
      allow(client).to receive(:initiate_multipart_upload).once.and_call_original
      2.times { subject.upload_id }
    end
  end

  describe '#write' do
    it 'uploads the chunk' do
      expect(client).to receive(:upload_part).with(
        'fake-bucket',
        'some/path',
        subject.upload_id,
        1,
        'some data',
        {}
      ).and_call_original

      subject.write 'some data'
    end

    it 'increments the part number' do
      allow(client).to receive(:upload_part).and_call_original
      expect(subject.part_number).to be 1
      subject.write 'some data'
      expect(subject.part_number).to eq 2
    end
  end

  describe '#finish' do
    before do
      allow(client).to receive(:initiate_multipart_upload).and_call_original
      subject.start
    end

    it 'completes the multipart upload' do
      expect(client).to receive(:complete_multipart_upload).with(
        'fake-bucket',
        'some/path',
        subject.upload_id,
        []
      ).and_call_original
      subject.finish
    end
  end
end
