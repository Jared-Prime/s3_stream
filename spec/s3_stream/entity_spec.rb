require 'spec_helper'

RSpec.describe S3Stream::Entity do
  subject do
    described_class.new(uid, :client => client, :bucket => 'fake-bucket', :filename => 'message.txt')
  end

  let(:uid) { 'some/path' }

  let(:client) do
    Fog::Storage.new(:provider => 'AWS',
                     :aws_access_key_id => 'key',
                     :aws_secret_access_key => 'secret')
  end

  before do
    Fog.mock!
    begin
      client.put_bucket 'fake-bucket'
    rescue Excon::Error::Conflict # rubocop:disable Lint/HandleExceptions
      # bucket already exists
    end

    client.put_object 'fake-bucket', uid, 'hello jeff bezos', {
      'Content-Type' => 'text/plain',
      'Content-Disposition' => 'attachment; filename="message.txt"'
    }
  end

  describe '#full_path' do
    context 'no S3 root path expected by default' do
      it 'returns the uid' do
        expect(subject.full_path).to be uid
      end
    end

    context 'S3 root path specified' do
      subject do
        described_class.new(
          uid, :client => client, :bucket => 'fake-bucket', :s3_root_path => hostname, :filename => 'message.txt'
        )
      end

      let(:hostname) { Socket.gethostname }

      it 'appends to the uid' do
        expect(subject.full_path).to eq File.join(hostname, 'some/path')
      end
    end
  end

  describe '#content_type' do
    it 'gives the object datas content type' do
      expect(subject.content_type).to eq 'text/plain'
    end
  end

  describe '#content_disposition' do
    it 'gives the presentational format of the data' do
      expect(subject.content_disposition).to eq 'attachment; filename="message.txt"'
    end
  end

  describe '#get' do
    context 'no block given' do
      it 'returns the full data' do
        expect(subject.get).to be_a Excon::Response
      end
    end

    context 'with a block' do
      it 'yields the full data to the given block' do
        subject.get do |chunk|
          expect(chunk).to eq 'hello jeff bezos'
        end
      end
    end
  end
end
