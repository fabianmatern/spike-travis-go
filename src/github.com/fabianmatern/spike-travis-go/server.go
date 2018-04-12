package main

import (
	. "fmt"
	"net/http"
	"time"
	"os"
	"math/rand"
	"github.com/julienschmidt/httprouter"
)

func main() {
	port := os.Getenv("PORT")
	router := httprouter.New()
	router.GET("/.well-known/live", func(w http.ResponseWriter, r *http.Request,  _ httprouter.Params) {
		w.Header().Set("Content-Type", "text/plain")
		Println("Hello World")
		Fprintf(w, "Hello World 1")
	})

	handler := func(w http.ResponseWriter, r *http.Request,  _ httprouter.Params) {
		w.Header().Set("Content-Type", "text/plain")
		randomNumberGenerator := rand.New(rand.NewSource(time.Now().UnixNano()))
		randomNumber := randomNumberGenerator.Intn(5)
		time.Sleep(time.Duration(randomNumber) * time.Second)
		str := Sprintf("Feature took %d", randomNumber)
		Println(str)
		Fprintf(w, str)
	}

	router.GET("/feature", handler)
	router.GET("/feature/:id", handler)
	router.GET("/feature/:id/status", handler)

	if e := http.ListenAndServe(port, router); e != nil {
		Println(e)
	}
}
