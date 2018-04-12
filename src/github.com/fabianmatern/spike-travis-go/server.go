package main

import (
	"net/http"
	"time"
	"os"
	"math/rand"
	"github.com/julienschmidt/httprouter"
	"github.com/fabianmatern/spike-travis-go/gocql"
	"fmt"
)

func main() {
	port := os.Getenv("PORT")
	router := httprouter.New()
	router.GET("/.well-known/live", func(w http.ResponseWriter, r *http.Request,  _ httprouter.Params) {
		w.Header().Set("Content-Type", "text/plain")
		fmt.Println("Hello World")
		fmt.Fprintf(w, "Hello World 1")
	})

	handler := func(w http.ResponseWriter, r *http.Request,  _ httprouter.Params) {
		w.Header().Set("Content-Type", "text/plain")
		randomNumberGenerator := rand.New(rand.NewSource(time.Now().UnixNano()))
		randomNumber := randomNumberGenerator.Intn(5)
		time.Sleep(time.Duration(randomNumber) * time.Second)
		str := fmt.Sprintf("Feature took %d", randomNumber)
		fmt.Println(str)
		fmt.Fprintf(w, str)
	}

	router.GET("/feature", handler)
	router.GET("/feature/:id", handler)
	router.GET("/feature/:id/status", handler)

	fmt.Println("Try to setup cluster.")

	db, err := gocql.Builder().Build(URL.Parse("cassandra://errorbudget-service-user:errorbudget-service-password@192.168.99.100:9042/resource?dc=datacenter1&host=cassandra"))

	fmt.Println(db, err)

	//cluster := gocql.NewCluster("192.168.99.100")
	//cluster.Keyspace = "system"
	//cluster.Consistency = gocql.Quorum
	//session, _ := cluster.CreateSession()
	//
	//
	///* Search for a specific set of records whose 'timeline' column matches
	// * the value 'me'. The secondary index that we created earlier will be
	// * used for optimizing the search */
	//
	//var vertical string
	//if err := session.Query(`SELECT vertical from onboarded_vertical`).Consistency(gocql.One).Scan(&vertical); err != nil {
	//	log.Fatal(err)
	//}
	//fmt.Println("Vertical:", vertical)


	if e := http.ListenAndServe(":" + port, router); e != nil {
		fmt.Println(e)
	}

}
