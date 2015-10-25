# Memot

[![Gem Version](https://badge.fury.io/rb/memot.svg)](https://badge.fury.io/rb/memot)
[![Code Climate](https://codeclimate.com/github/dtan4/memot/badges/gpa.svg)](https://codeclimate.com/github/dtan4/memot)

Synchronize Evernote and Markdown in Dropbox

(TODO: Add image)

## Installation

```shell
$ gem install memot
$ memot
```

## Usage

## Configure

You can choose configuration style:

- `~/.memot.yml`
- Environment variables

### `~/.memot.yml`

Create `~/.memot.yml` and fill this.

```yaml
auth:
  evernote:
    token:
    sandbox: false
  dropbox:
    app_key:
    app_secret:
    access_token:
notes:
  <evernote_notebook>: <dropbox_path>
  # example
  daily: /memo/daily
  reading: /memo/reading
```

### Environment variables

key | type | example
----|------|-----
MEMOT_DROPBOX_APP_KEY | string |
MEMOT_DROPBOX_APP_SECRET | string |
MEMOT_DROPBOX_ACCESS_TOKEN | string |
MEMOT_EVERNOTE_TOKEN | string |
MEMOT_EVERNOTE_SANDBOX | boolean | `false`
MEMOT_NOTES | string | `daily:/memo/daily,reading:/memo/reading`

MEMOT_NOTES: `<evernote_notebook1>:<dropbox_path1>[,<evernote_notebook2>:<dropbox_path2> ...]`

## Docker image

Memot Docker image is available at [quay.io/dtan4/memot](https://quay.io/repository/dtan4/memot).

[![Docker Repository on Quay.io](https://quay.io/repository/dtan4/memot/status "Docker Repository on Quay.io")](https://quay.io/repository/dtan4/memot)

```shell
$ docker run -e MEMOT_DROPBOX_APP_KEY=... quay.io/dtan4/memot
```

This image runs `memot` every 15 minutes.
If you'd like to configure interval, specify command explicitly.

```shell
# Run every 30 minutes
$ docker run -e MEMOT_DROPBOX_APP_KEY=... quay.io/dtan4/memot bundle exec bin/memot -i 30
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

MIT
