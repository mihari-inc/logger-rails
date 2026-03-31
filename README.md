# Mihari Rails

Rails integration for the [Mihari](https://mihari.io) structured log transport library. Ships request logs, ActiveRecord queries, and ActionController events to Mihari with zero-config Railtie setup.

## Installation

Add to your Gemfile:

```ruby
gem "mihari-rails"
```

Then run:

```bash
bundle install
```

## Configuration

### Minimal setup

Set the `MIHARI_TOKEN` environment variable and the gem auto-configures via Railtie:

```bash
export MIHARI_TOKEN="your-token-here"
```

### Explicit configuration

In `config/application.rb` (or any environment file):

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    config.mihari.token       = ENV.fetch("MIHARI_TOKEN")
    config.mihari.source_name = "my-rails-app"
    config.mihari.endpoint    = "https://in.logs.mihari.io"

    # Batching
    config.mihari.flush_interval = 5   # seconds
    config.mihari.batch_size     = 100

    # Transport
    config.mihari.gzip = true

    # Feature flags
    config.mihari.auto_attach_middleware = true
    config.mihari.log_active_record     = true
    config.mihari.log_action_controller = true
    config.mihari.capture_request_id    = true
    config.mihari.capture_user_agent    = true
    config.mihari.capture_ip            = true

    # Overrides (auto-detected from Rails if omitted)
    config.mihari.environment = Rails.env
    config.mihari.app_name    = "my-app"
  end
end
```

### Per-environment configuration

```ruby
# config/environments/production.rb
config.mihari.token    = ENV.fetch("MIHARI_TOKEN")
config.mihari.gzip     = true

# config/environments/development.rb
config.mihari.token    = ENV["MIHARI_TOKEN"]
config.mihari.gzip     = false
```

## What gets logged

### Rack middleware (request logging)

Every HTTP request is automatically logged with:

```json
{
  "dt": "2026-03-31T12:00:00Z",
  "level": "info",
  "message": "GET /users/1 200 12.34ms",
  "http": {
    "method": "GET",
    "path": "/users/1",
    "status": 200,
    "duration_ms": 12.34,
    "request_id": "req-abc-123",
    "user_agent": "Mozilla/5.0 ...",
    "ip": "203.0.113.1"
  },
  "rails": {
    "environment": "production",
    "app_name": "my-app"
  }
}
```

### ActionController events

Controller action processing with view and DB timing breakdown:

```json
{
  "dt": "2026-03-31T12:00:00Z",
  "level": "info",
  "message": "UsersController#show 200 in 45.67ms",
  "action_controller": {
    "controller": "UsersController",
    "action": "show",
    "format": "html",
    "method": "GET",
    "path": "/users/1",
    "status": 200,
    "duration_ms": 45.67,
    "view_runtime_ms": 30.12,
    "db_runtime_ms": 5.43
  }
}
```

### ActiveRecord queries

SQL queries logged at debug level (SCHEMA and CACHE queries are excluded):

```json
{
  "dt": "2026-03-31T12:00:00Z",
  "level": "debug",
  "message": "SQL User Load (1.23ms)",
  "active_record": {
    "name": "User Load",
    "sql": "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = $1",
    "duration_ms": 1.23,
    "cached": false
  }
}
```

### Tagged logging

When using `Rails.logger.tagged`, tags are forwarded to Mihari:

```ruby
Rails.logger.tagged("RequestID:abc") do
  Rails.logger.info("Processing payment")
end
```

Produces:

```json
{
  "level": "info",
  "message": "Processing payment",
  "tags": ["RequestID:abc"]
}
```

## Disabling features

```ruby
# Skip middleware (no automatic request logging)
config.mihari.auto_attach_middleware = false

# Skip ActiveRecord query logging
config.mihari.log_active_record = false

# Skip ActionController event logging
config.mihari.log_action_controller = false

# Skip specific request metadata
config.mihari.capture_request_id = false
config.mihari.capture_user_agent = false
config.mihari.capture_ip         = false
```

## API format

Logs are sent as JSON to the configured endpoint with:

- **Authorization**: `Bearer <token>`
- **Content-Type**: `application/json`
- **Content-Encoding**: `gzip` (when enabled)

Each log entry follows the format:

```json
{
  "dt": "ISO8601_timestamp",
  "level": "info",
  "message": "...",
  ...
}
```

Accepted response: `202 { "status": "accepted", "count": N }`

## Development

```bash
bundle install
bundle exec rake spec
```

## License

MIT License. See [LICENSE](LICENSE) for details.
