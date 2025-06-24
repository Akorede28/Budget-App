# ─── builder stage ───────────────────────────────────────────────────────────
FROM ruby:3.1.2 AS builder

WORKDIR /app

# 1) Only copy Gemfile & lock so that `bundle install` is cached
COPY Gemfile* ./
RUN bundle config set without 'development test' \
 && bundle install --jobs=4 --retry=3

# 2) Only copy package.json & lock so that `yarn install` is cached
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --production

# 3) Copy the rest of your code, compile assets, etc.
COPY . .
RUN RAILS_ENV=production bundle exec rails assets:precompile

# ─── final image ─────────────────────────────────────────────────────────────
FROM ruby:3.1.2-slim

WORKDIR /app

# Install only runtime OS deps
RUN apt-get update && apt-get install -y \
    libpq5 nodejs \
 && rm -rf /var/lib/apt/lists/*

# Copy in everything from builder
COPY --from=builder /app /app

# Use a non‐root user if you’d like
USER nobody:nogroup

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
