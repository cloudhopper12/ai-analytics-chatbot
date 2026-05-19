# Database

The database is split into:

- `schema.sql`: analytics tables, app persistence tables, indexes, grants.
- `seed.sql`: deterministic e-commerce sample data.

The setup script creates two roles:

- `analytics_app`: writes app metadata and reads analytics data.
- `analytics_readonly`: executes approved analysis queries only.

Postgres should stay local to the remote dev machine. The web app and API are exposed to the MacBook; the database is not.
