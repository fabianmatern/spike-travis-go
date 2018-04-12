package gocql

import (
	"fmt"
	"net/url"
	"time"

	"github.com/gocql/gocql"
)

// A builder for creating DB connection
type builder struct {
	timeout                time.Duration
	socketKeepalive        time.Duration
	maxWaitSchemaAgreement time.Duration
	cluster                *gocql.ClusterConfig
}

// Builder returns a new connector builder object based on
// the provided URI. The builder will build
// with the following defaults:
// - Connection timeout: 1s
// - TCP keep alive: disabled
// - Max. wait time for schema agreement: 5s
// - consistency level: LOCAL_ONE
// - serial consistency level: LOCAL_SERIAL
// And the defaults of the gocql package.
func Builder() *builder {
	return &builder{
		timeout:                5 * time.Second,
		socketKeepalive:        0,
		maxWaitSchemaAgreement: 5 * time.Second,
	}
}

// WithConnectTimeout sets the TCP connection timeout.
func (b *builder) WithConnectTimeout(d time.Duration) *builder {
	b.timeout = d
	return b
}

// WithSchemaAgreementTimeout sets the schema agreement timeout.
func (b *builder) WithSchemaAgreementTimeout(d time.Duration) *builder {
	b.maxWaitSchemaAgreement = d
	return b
}

// Build builds the Db instance
func (b *builder) Build(uri *url.URL) (IDb, error) {
	var cluster *gocql.ClusterConfig
	db := &Db{}

	dc := uri.Query().Get("dc")
	if dc == "" {
		return nil, fmt.Errorf("Datacenter not set in Cassandra URI %s; please provide the name using dc query parameter", uri.String())
	}

	if len(uri.Path) < 2 {
		return nil, fmt.Errorf("Keyspace not set in Cassandra URI %s; please provide the name as URI path", uri.String())
	}

	hosts := uri.Query()["host"]
	hosts = append(hosts, uri.Host)
	cluster = gocql.NewCluster(hosts...)
	cluster.Keyspace = uri.Path[1:]
	cluster.SerialConsistency = gocql.LocalSerial
	cluster.Consistency = gocql.LocalOne
	cluster.Timeout = b.timeout
	cluster.SocketKeepalive = b.socketKeepalive
	cluster.MaxWaitSchemaAgreement = b.maxWaitSchemaAgreement

	// API was undocumented at the time of coding. Details in
	// https://groups.google.com/forum/#!topic/gocql/L-sMOehwRqc
	cluster.HostFilter = gocql.DataCentreHostFilter(dc)
	if userInfo := uri.User; userInfo != nil {
		pwd, _ := userInfo.Password()

		cluster.Authenticator = gocql.PasswordAuthenticator{
			Username: userInfo.Username(),
			Password: pwd,
		}
	}

	db.cluster = cluster
	session, err := cluster.CreateSession()
	if err != nil {
		return nil, err
	}

	db.session = session
	return db, nil
}

func SetLogger(logger gocql.StdLogger) {
	gocql.Logger = logger
}
