include("../../protobuf/AnyonClients.jl")
using LinearAlgebra: getproperty
using UUIDs
using .AnyonClients
using gRPCClient
using StatsBase: countmap


@enum JobStatus UNKNOWN = 0 QUEUED = 1 RUNNING = 2 SUCCEEDED = 3 FAILED = 4 CANCELED = 5
JobStatusMap = Dict(
    UNKNOWN => "UNKNOWN",
    QUEUED => "QUEUED",
    RUNNING => "RUNNING",
    SUCCEEDED => "SUCCEEDED",
    FAILED => "FAILED",
    CANCELED => "CANCELED",
)
IntToJobStatusMap = Dict(
    0 => UNKNOWN,
    1 => QUEUED,
    2 => RUNNING,
    3 => SUCCEEDED,
    4 => FAILED,
    5 => CANCELED,
)

function Base.string(status::JobStatus)
    return JobStatusMap[status]
end

function submit_circuit(
    circuit::QuantumCircuit;
    username::String,
    password::String,
    shots::Int,
    host::String,
)
    client = AnyonClients.CircuitAPIBlockingClient(host)
    request = create_job_request(circuit, username = username, password = password, shots = shots)

    reply = Snowflake.AnyonClients.anyon.public.snowflake.submitJob(client, request)
    job_uuid = getproperty(reply[1], :job_uuid)
    status = getproperty(reply[1], :status)
    message = getproperty(status, :message)
    status_type = getproperty(status, :_type)

    return job_uuid, IntToJobStatusMap[status_type]
end

function create_job_request(
    circuit::QuantumCircuit;
    username::String,
    password::String,
    shots::Int,
)
    pipeline = []
    for step in circuit.pipeline
        should_add_identity = fill(true, circuit.qubit_count)
        for gate in step

            # flag if the qubit is being operated on in this step
            for i_qubit in gate.target
                should_add_identity[i_qubit] = false
            end

            ##TODO: add classical bit targets and parameters
            push!(
                pipeline,
                AnyonClients.Instruction(
                    symbol = gate.instruction_symbol,
                    qubits = gate.target,
                ),
            )
        end

        for i_qubit in range(1, length = (circuit.qubit_count))
            if (should_add_identity[i_qubit])
                push!(pipeline, AnyonClients.Instruction(symbol = "i", qubits = [i_qubit]))
            end
        end

    end

    circuit_api = AnyonClients.anyon.public.snowflake.Circuit(instructions = pipeline)
    request = AnyonClients.SubmitJobRequest(
        username = username,
        password = password,
        shots_count = shots,
        circuit = circuit_api,
    )

    return request
end

function get_circuit_status(
    job_uuid::String;
    username::String,
    password::String,
    host::String,
)
    client = AnyonClients.CircuitAPIBlockingClient(host)
    request = AnyonClients.JobStatusRequest(job_uuid = job_uuid, username = username, password = password)

    reply = Snowflake.AnyonClients.anyon.public.snowflake.getJobStatus(client, request)
    status_obj = getproperty(reply[1], :status)
    msg = getproperty(status_obj, :message)
    status = getproperty(status_obj, :_type)

    return IntToJobStatusMap[status], msg
end

function get_circuit_result(
    job_uuid::String;
    username::String,
    password::String,
    host::String,
)
    client = AnyonClients.CircuitAPIBlockingClient(host)
    request = AnyonClients.JobResultRequest(job_uuid = job_uuid, username = username, password = password)

    reply = Snowflake.AnyonClients.anyon.public.snowflake.getJobResult(client, request)
    job_uuid = getproperty(reply[1], :job_uuid)
    job_results = getproperty(reply[1], :results)[1]
    job_result = getproperty(job_results, :shot_read_out)
    status_obj = getproperty(reply[1], :status)
    msg = getproperty(status_obj, :message)
    status = getproperty(status_obj, :_type)

    return countmap(map(String, job_result)), IntToJobStatusMap[status], msg
end
