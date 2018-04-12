package main_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	// . "github.com/dydyistc/spike-travis-go"
)

var _ = Describe("SpikeTravisGo", func() {
	It("should run test", func() {
		Expect(1 - 1).Should(BeZero())
	})

})
