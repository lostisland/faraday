# Test Infrastructure for Faraday Integration Tests

This directory documents the services used in Faraday's integration tests. All services use public Docker images and run as GitHub Actions service containers during CI.

## Services

### 1. httpbin (`mccutchen/go-httpbin`)

**Purpose**: HTTP and HTTPS testing service providing various endpoints for testing HTTP requests and SSL/TLS.

**Image**: `mccutchen/go-httpbin:latest` (public image, no custom build needed)

**Key Endpoints** (available at `http://httpbin:8080` in tests):

**HTTP Testing:**
- `/get` - Returns GET request data (JSON)
- `/post` - Returns POST request data (JSON)
- `/put`, `/patch`, `/delete` - Other HTTP methods
- `/status/:code` - Returns specified HTTP status code
- `/headers` - Returns request headers
- `/delay/:n` - Delays response by n seconds (max 10)
- `/stream-bytes/:n` - Streams n random bytes
- `/stream/:n` - Streams n JSON responses
- `/bytes/:n` - Generates n random bytes
- `/drip` - Drips data over duration

**SSL/TLS Testing:**
- Supports HTTPS mode for SSL testing
- Can test certificate verification (verify: true/false)
- Self-signed certificate mode available

**Usage in tests**:
```ruby
HTTPBIN_URL = 'http://httpbin:8080'
```

**Reference**: [go-httpbin documentation](https://github.com/mccutchen/go-httpbin)

---

### 2. Proxy Server (`ubuntu/squid`) - Future

**Purpose**: HTTP proxy server for testing proxy configuration and authentication.

**Image**: `ubuntu/squid:latest` (public image, no custom build needed)

**Configuration**: Default Squid configuration suitable for testing

**Usage in tests** (when enabled):
```ruby
PROXY_URL = 'http://proxy:3128'
```

**To enable**: Uncomment proxy service in `.github/workflows/integration-tests.yml`

---

## GitHub Actions Integration

These services run as [service containers](https://docs.github.com/en/actions/using-containerized-services/about-service-containers) in GitHub Actions workflows.

### Workflow Configuration

See `.github/workflows/integration-tests.yml`:

```yaml
services:
  httpbin:
    image: mccutchen/go-httpbin:latest
    options: >-
      --health-cmd "wget --spider http://localhost:8080/get"
      --health-interval 5s
      --health-retries 10
```

### Networking

When running in GitHub Actions **container jobs**:
- Services are accessible by service name (e.g., `http://httpbin:8080`)
- No port mapping required
- All containers on same Docker network
- Health checks ensure services are ready before tests run

---

## Local Testing

### Run httpbin Locally

```bash
# HTTP mode
docker run -p 8080:8080 mccutchen/go-httpbin

# Test it
curl http://localhost:8080/get
```

### Run Proxy Locally

```bash
# Start Squid proxy
docker run -p 3128:3128 ubuntu/squid

# Test it
curl -x http://localhost:3128 http://example.com
```

---

## Adding More Services

To add new services to integration tests:

1. Find a suitable public Docker image
2. Add to `.github/workflows/integration-tests.yml` services section
3. Configure health check using `--health-cmd`
4. Update `spec/integration/support/integration_helper.rb` with service URL
5. Document in this README

**Prefer public images over custom builds** for maintainability.

---

## Troubleshooting

### Service Not Ready

If integration tests fail with connection errors:

1. Check health check configuration in workflow
2. Increase `--health-retries` or `--health-start-period`
3. Verify service name resolution (e.g., `curl http://httpbin:8080/get`)
4. Check service logs in GitHub Actions

### Connection Refused

- Ensure running in container job (not runner job)
- Verify service name (not localhost)
- Check port matches service configuration

---

## References

- [GitHub Actions Service Containers](https://docs.github.com/en/actions/using-containerized-services/about-service-containers)
- [mccutchen/go-httpbin](https://github.com/mccutchen/go-httpbin)
- [ubuntu/squid Docker image](https://hub.docker.com/r/ubuntu/squid)
