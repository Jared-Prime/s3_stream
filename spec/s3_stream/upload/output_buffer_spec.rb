RSpec.describe S3Stream::Upload::OutputBuffer do
  subject { described_class.new output_writer, :maxsize => 2 }

  let(:output_writer) { instance_double S3Stream::Upload::OutputWriter }

  context 'private methods' do
    describe '#default_max_size' do
      it 'gives a default max size of 100MB' do
        output_buffer = described_class.new output_writer

        val = output_buffer.send :default_max_size

        expect(val).to be 104_857_600
      end

      it 'sets the maxsize to the default if none given' do
        output_buffer = described_class.new output_writer

        expect(output_buffer.maxsize).to be 104_857_600
      end
    end

    describe '#minimum_max_size' do
      it 'gives AWS minimum upload part size of 5MB' do
        output_buffer = described_class.new output_writer

        val = output_buffer.send :minimum_max_size

        expect(val).to be 5_242_880
      end

      it 'raises an ArgumentError when given a maxsize below the minimum' do
        expect { described_class.new output_writer, :maxsize => S3Stream::Upload::OutputBuffer::MB }
          .to raise_error(ArgumentError, 'maxsize must be at least 5 MB in size')
      end
    end
  end

  describe '#write' do
    # override AWS default minimum upload size to simplify tests
    before do
      allow_any_instance_of(described_class)
        .to receive(:minimum_max_size)
        .and_return 0
    end

    it 'flushes when internal buffer reaches maxsize' do
      expect(output_writer).to receive(:<<).with 'ab'
      subject.write 'a'
      subject.write 'b'
    end

    it 'returns self for chaining' do
      allow(output_writer).to receive(:<<)
      res = subject.write 'a'
      expect(res).to be subject
    end
  end

  describe '#flush' do
    # override AWS default minimum upload size to simplify tests
    before do
      allow_any_instance_of(described_class)
        .to receive(:minimum_max_size)
        .and_return 0
    end

    it 'empties the internal buffer' do
      allow(output_writer).to receive(:<<)
      subject.write 'a'
      expect(subject.size).to be 1

      subject.flush
      expect(subject.size).to be_zero
    end

    it 'pushes to the output writer' do
      expect(output_writer).to receive(:<<).with 'a'
      subject.write 'a'
      subject.flush
    end
  end

  describe '#finish' do
    # override AWS default minimum upload size to simplify tests
    before do
      allow_any_instance_of(described_class)
        .to receive(:minimum_max_size)
        .and_return 0
    end

    before do
      allow(output_writer).to receive(:<<)
      allow(output_writer).to receive(:finish)
      subject.write 'a'
    end

    it 'finishes the destination object' do
      expect(output_writer).to receive(:finish)
      subject.finish
    end

    it 'flushes the remaining buffer' do
      expect(output_writer).to receive(:<<).with 'a'
      subject.finish
    end

    it 'returns the destination object' do
      expect(output_writer).to receive(:finish)
      res = subject.finish
      expect(res).to be output_writer
    end
  end
end
