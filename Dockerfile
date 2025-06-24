# --- STAGE 1: Install and compile gems & assets ---
FROM ruby:3.1.2-alpine AS builder

# install build deps
RUN apk add --no-cache \
      build-base \
      git \
      libpq-dev \
      nodejs \
      npm \
      tzdata

WORKDIR /app

# copy Gemfile first to leverage layer caching
COPY Gemfile Gemfile.lock ./
# install only production gems (skip dev/test)
RUN bundle config set without 'development test' \
 && bundle install --jobs 4 --retry 3

# if you have a package.json / yarn.lock for frontend:
COPY package.json yarn.lock ./
RUN npm install -g yarn \
 && yarn install --production --silent

# copy the rest of the app
COPY . .

# precompile assets (if you use webpacker/assets pipeline)
RUN RAILS_ENV=production bundle exec rails assets:precompile

# --- STAGE 2: Runtime image ---
FROM ruby:3.1.2-alpine

# install only run-time deps
RUN apk add --no-cache \
      nodejs \
      postgresql-client \
      tzdata

WORKDIR /app

# copy compiled gems and app from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

# set production env
ENV RAILS_ENV=production \
    RACK_ENV=production

EXPOSE 3000

# use Puma or your server of choice
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
