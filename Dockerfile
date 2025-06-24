FROM ruby:3.1.2 AS builder
WORKDIR /app
COPY Gemfile* ./
RUN bundle install --jobs 4 --retry 3
COPY . .

FROM ruby:3.1.2-slim
WORKDIR /app
COPY --from=builder /app /app
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
