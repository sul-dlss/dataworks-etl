# dataworks-etl
ETL application for Dataworks

## Data model

### Dataset source
The metadata for a dataset as retrieved from a provider. A Dataset Source may be associated with many Datasource Source Sets.

### Dataset source set
Set of Dataset Source records that were extracted from a provider by a single job.

A Dataset Source Set is marked as complete if the job was successful (the metadata for all datasets was retrieved).

## Configuration

### Schedule
The job schedule is set in `config/recurring.yml`.

## Development

### Requirements

* docker & docker compose
* tmux ([installation instructions](https://github.com/tmux/tmux#installation))
* overmind ([installed automatically via bundler](https://github.com/DarthSim/overmind/tree/master/packaging/rubygems#installation-with-rails))

### Credentials
Create credentials and add to `config/settings/development.local.yml`:
```
redivis:
  api_token: ~

zenodo:
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