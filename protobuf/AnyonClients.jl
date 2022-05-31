module AnyonClients
using gRPCClient

include("anyon.jl")
using .anyon.public.snowflake

import Base: show

# begin service: anyon.public.snowflake.CircuitAPI

export CircuitAPIBlockingClient, CircuitAPIClient

struct CircuitAPIBlockingClient
    controller::gRPCController
    channel::gRPCChannel
    stub::CircuitAPIBlockingStub

    function CircuitAPIBlockingClient(api_base_url::String; kwargs...)
        controller = gRPCController(; kwargs...)
        channel = gRPCChannel(api_base_url)
        stub = CircuitAPIBlockingStub(channel)
        new(controller, channel, stub)
    end
end

struct CircuitAPIClient
    controller::gRPCController
    channel::gRPCChannel
    stub::CircuitAPIStub

    function CircuitAPIClient(api_base_url::String; kwargs...)
        controller = gRPCController(; kwargs...)
        channel = gRPCChannel(api_base_url)
        stub = CircuitAPIStub(channel)
        new(controller, channel, stub)
    end
end

show(io::IO, client::CircuitAPIBlockingClient) = print(io, "CircuitAPIBlockingClient(", client.channel.baseurl, ")")
show(io::IO, client::CircuitAPIClient) = print(io, "CircuitAPIClient(", client.channel.baseurl, ")")

import .anyon.public.snowflake: submitJob
"""
    submitJob

- input: anyon.public.snowflake.SubmitJobRequest
- output: anyon.public.snowflake.SubmitJobReply
"""
submitJob(client::CircuitAPIBlockingClient, inp::anyon.public.snowflake.SubmitJobRequest) = submitJob(client.stub, client.controller, inp)
submitJob(client::CircuitAPIClient, inp::anyon.public.snowflake.SubmitJobRequest, done::Function) = submitJob(client.stub, client.controller, inp, done)

import .anyon.public.snowflake: getJobStatus
"""
    getJobStatus

- input: anyon.public.snowflake.JobStatusRequest
- output: anyon.public.snowflake.JobStatusReply
"""
getJobStatus(client::CircuitAPIBlockingClient, inp::anyon.public.snowflake.JobStatusRequest) = getJobStatus(client.stub, client.controller, inp)
getJobStatus(client::CircuitAPIClient, inp::anyon.public.snowflake.JobStatusRequest, done::Function) = getJobStatus(client.stub, client.controller, inp, done)

import .anyon.public.snowflake: getJobResult
"""
    getJobResult

- input: anyon.public.snowflake.JobResultRequest
- output: anyon.public.snowflake.JobResultReply
"""
getJobResult(client::CircuitAPIBlockingClient, inp::anyon.public.snowflake.JobResultRequest) = getJobResult(client.stub, client.controller, inp)
getJobResult(client::CircuitAPIClient, inp::anyon.public.snowflake.JobResultRequest, done::Function) = getJobResult(client.stub, client.controller, inp, done)

# end service: anyon.public.snowflake.CircuitAPI

end # module AnyonClients
