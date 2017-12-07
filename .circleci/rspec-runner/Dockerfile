FROM ruby:2.3.5

COPY . /usr/src/app/
WORKDIR /usr/src/app
RUN bundle install --path=vendor/bundle --jobs=4

