FROM ruby:2.2.0

RUN mkdir /app
COPY . /app
WORKDIR /app
RUN bundle install --without development --system

CMD ["bundle", "exec", "bin/memot", "-i", "15"]
