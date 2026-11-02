.. ©AngelaMos | 2026
.. SECURITY.rst

Website runtime
===============

``cmd/api/routes.go`` registers health checks, the contact form, cached public
Instagram/GitHub statistics, and the public statistics WebSocket. The template
authentication, registration, user, admin, and JWKS handlers are not registered.
JWT keys are not loaded at startup or copied into new container images.
Postgres storage and existing data are unchanged.

Missing API routes return a JSON ``NOT_FOUND`` error with HTTP 404. Wrong methods
return JSON with HTTP 405. Nginx serves the frontend 404 page with HTTP 404 for
unknown page paths; missing scripts and installer files never fall back to a
successful HTML response. Add new public page routes to both React Router and
the explicit page-route location in ``infra/nginx/prod.nginx``.

Proxy boundary
==============

The production ingress network is ``10.253.249.0/29``. Nginx uses
``10.253.249.2`` and the tunnel uses ``10.253.249.3``. Nginx accepts
``CF-Connecting-IP`` only from the tunnel's address. Other requests keep their
socket peer address. Nginx replaces incoming forwarded-IP headers before
proxying to the API, which is not published on a host port. The nginx host port
binds to loopback. Keep this address assignment and ``set_real_ip_from`` aligned.

Deploy the API, nginx, and tunnel together after building both images. The
tunnel's origin should remain ``http://nginx:80`` on the shared ingress network.
The existing Postgres and Redis services do not need recreation for these
changes. The new ingress subnet must be free before deployment.

Request controls
================

The contact limiter has a separate Redis namespace from the general API limiter.
It allows a burst of two requests and replenishes at five requests per hour.
Redis errors use the existing in-process fallback, whose access timestamps are
now atomic. Contact bodies are limited to 32 KiB and must contain one JSON
object with recognized fields. Whitespace-only fields are rejected.

The WebSocket uses the library's same-origin verification. Nginx preserves the
original Host including the port for this check and limits concurrent sockets
per client IP. The API has a five-second header timeout and a 16 KiB header cap.
Instagram request errors omit the token-bearing URL and upstream error bodies.

Browser response headers live at the nginx server level, including cache policy,
so per-location cache directives cannot suppress them. Scripts are restricted to
the site's origin and ``https://static.cloudflareinsights.com`` for the existing
Cloudflare analytics beacon. Analytics connections also allow
``https://cloudflareinsights.com``. Inline styles remain allowed for React styles
and existing visual effects. Production source maps are neither generated nor
served.

Static-analysis exceptions
==========================

``.golangci.yml`` scopes G117 exceptions to the dormant auth/user API DTO files,
where passwords are request fields and tokens are deliberate response fields.
The G101 exception covers only the ``envKeyMap`` declaration, which contains
environment-variable names and config paths, not credential values.

G704 exceptions cover only the three outbound request call sites for Resend,
GitHub, and Instagram. Their HTTPS origins are fixed in source; configuration
values are escaped path segments or request data. Reassess these exceptions if
an origin becomes caller-controlled.

Verification
============

``just go-test`` runs the Go race suite. Set ``TEST_REDIS_ADDR`` to a disposable
Redis address to include the global/contact namespace isolation test. Never
point that integration test at production Redis. ``just go-lint`` checks the
entire backend. ``just installer-check`` checks installer syntax and checksums.

The November 2026 local preview verified both themes across desktop and mobile,
theme persistence, blocked local storage, real frontend/API 404s, 405 responses,
security headers, all 36 installer downloads, forged forwarding headers,
separate trusted visitor quotas, and both WebSocket origin cases. The homepage
matched the existing production container pixel for pixel at 1440 by 1000.
The email transport was mocked in tests; no test email was sent.

References: `nginx header inheritance
<https://nginx.org/en/docs/http/ngx_http_headers_module.html#add_header>`_,
`Cloudflare visitor headers
<https://developers.cloudflare.com/fundamentals/reference/http-headers/>`_,
`Cloudflare analytics CSP requirements
<https://developers.cloudflare.com/fundamentals/reference/policies-compliances/content-security-policies/>`_, and
`Go request body limits <https://pkg.go.dev/net/http#MaxBytesReader>`_.
