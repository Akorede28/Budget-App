# syntax=docker/dockerfile:1

####################################
# 1) Builder Stage: compile gems & assets
####################################
FROM ruby:3.1.2-slim AS builder

# Install only build-time deps
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential libpq-dev nodejs yarn && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1.1) Install gems
COPY Gemfile Gemfile.lock ./
# Skip groups we don’t need at build-time
RUN bundle config set without 'development test' \
  && bundle install --jobs 4 --retry 3

# 1.2) Copy code & precompile assets
COPY . .
ENV RAILS_ENV=production RACK_ENV=production
RUN bundle exec rails assets:precompile

####################################
# 2) Runtime Stage: lean production image
####################################
FROM ruby:3.1.2-slim

# Install only runtime deps
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends libpq-dev nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy gems and compiled app from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app        /app

# Make sure we run in prod
ENV RAILS_ENV=production RACK_ENV=production PORT=3000

EXPOSE 3000

# Start Puma
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
