[![codecov](https://codecov.io/gh/sul-dlss/dataworks-etl/graph/badge.svg?token=GRM1JU56U1)](https://codecov.io/gh/sul-dlss/dataworks-etl)

# dataworks-etl
ETL application for Dataworks

## Data model

### Dataset source
The metadata for a dataset as retrieved from a provider. A Dataset Source may be associated with many Datasource Source Sets.

### Dataset source set
Set of Dataset Source records that were extracted from a provider by a single job.

A Dataset Source Set is marked as complete if the job was successful (the metadata for all datasets was retrieved).

## Configuration

### Extra (hardcoded) datasets for providers
Extra datasets for a provider can be added to `config/datasets/<provider>.yml`.

### Local dataset metadata
Local metadata can be added to `config/local_datasets/<id>.yml`. The metadata must conform to the Dataworks schema.

### Schedule
The job schedule is set in `config/recurring.yml`.

### Honeybadger checkins
Jobs in deployed environments use Honeybadger checkins to verify that they are running. The checkin ids are environment specific and are set (from Vault) as `SETTINGS__HONEYBADGER__*` environment variables in puppet. The `config` gem maps these onto the `honeybadger` keys defined in `config/settings.yml`.

## Development

### Requirements

* docker & docker compose
* tmux ([installation instructions](https://github.com/tmux/tmux#installation))
* overmind ([installed automatically via bundler](https://github.com/DarthSim/overmind/tree/master/packaging/rubygems#installation-with-rails))

### Credentials
Create credentials and add to `config/settings/development.local.yml`. Only Redivis
requires a token; the other providers work unauthenticated but get higher rate limits
when credentials are supplied:
```
redivis:
  api_token: ~ # required

datacite:
  username: ~
  password: ~

zenodo:
  api_token: ~

open_alex:
  api_token: ~
```

### Running locally

Spin up containers and the app, and then set up the application and solid-* databases:

```shell
docker compose up -d
bin/rails db:prepare
bin/dev
```

## Mission Control (jobs monitoring)
Solid Queue jobs can be monitored with Mission Control at `/jobs`.

## Solr
In development, the dataworks core is available at http://localhost:8983/solr/#/dataworks/core-overview.

## SDR indexing
Most providers are harvested on a schedule (see `config/recurring.yml`), but datasets
self-deposited in the Stanford Digital Repository (SDR) are indexed incrementally as
they change. `SdrConsumer` (a [Racecar](https://github.com/zendesk/racecar) Kafka
consumer) subscribes to a purl-fetcher topic of SDR item updates, filters to
self-deposited datasets released to our targets, fetches the Cocina metadata from PURL,
and stores each as an `sdr` `DatasetRecord`. It reports indexing status back to SDR via
`SdrEvents` (RabbitMQ), which appears in the item's event log in Argo.

Relevant settings: `indexer_topic` (e.g. `purl_fetcher_prod`), `indexer_group`,
`purl.hostname`, `purl_fetcher.targets`/`skip_collections`, and `sdr_events` (disabled
in local dev).

In deployed environments the consumer runs as a systemd service (managed by Capistrano,
`:indexer` role), so it is not part of `bin/dev`. It requires a Kafka broker, which is
not included in `compose.yaml`. To index specific items locally without a broker, use
the consumer directly in the Rails console:
```ruby
SdrConsumer.new.update_item('xx123yy4567')
```
or run the batch rake task over the druids listed in `config/datasets/sdr_rake.yml`:
```shell
bin/rake development:sdr_update
```

## Testing transforms
```
bin/rake "development:transform_dryrun[<provider, e.g., redivis>]"
```