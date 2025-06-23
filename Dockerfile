# Dockerfile
FROM ruby:3.1.2

# install OS dependencies for pg and assets
RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
    build-essential libpq-dev nodejs yarn \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# copy Gemfile & lock and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set without 'production' \
 && bundle install --jobs 4 --retry 3

# copy the rest of your app
COPY . .

# expose default Rails port
EXPOSE 3000

# by default create/migrate DB then launch Puma
CMD ["bash", "-lc", "bundle exec rails db:create db:migrate && bundle exec rails server -b 0.0.0.0"]
