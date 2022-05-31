#!/bin/env julia


using gRPCClient

gRPCClient.generate("./proto/circuit.proto")
