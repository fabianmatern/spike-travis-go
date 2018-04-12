package gocql

import (
	"errors"
	"fmt"
	"github.com/gocql/gocql"
)

// IDb implements a cassandra connector component around
// the driver.
type IDb interface {
	Session() *gocql.Session
	ExecQuery(statement string, values ...interface{}) error
}

type Db struct {
	cluster *gocql.ClusterConfig
	session *gocql.Session
}

// Session returns the underlying gocql Session object.
func (db *Db) Session() *gocql.Session {
	return db.session
}

// CheckHealth implements health.Component's health check method.
func (db *Db) CheckReady() error {
	if db.session.Closed() {
		return errors.New("Session is closed")
	}

	if err := db.session.Query("SELECT now() FROM system.local").Exec(); err != nil {
		return fmt.Errorf("Health check query failed: %s", err.Error())
	}

	return nil
}

func (db *Db) ExecQuery(statement string, values ...interface{}) error {
	return db.session.Query(statement, values...).Exec()
}
