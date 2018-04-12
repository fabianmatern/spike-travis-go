package main

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestSpikeTravisGo(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "SpikeTravisGo Suite")
}
