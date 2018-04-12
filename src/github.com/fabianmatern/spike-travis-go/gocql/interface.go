package gocql

import (
	"net/url"
)

type IBuilder interface {
	Build(uri *url.URL) (IDb, error)
}
