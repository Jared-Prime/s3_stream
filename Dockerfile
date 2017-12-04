FROM ruby:2.4.2

COPY Gemfile .
COPY Gemfile.lock .
COPY s3_stream.gemspec .
COPY lib/version.rb lib/version.rb

RUN bundle install

COPY spec/ spec
COPY lib/ lib
COPY .rspec .

CMD ["bundle", "exec", "rspec"]