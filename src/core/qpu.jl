"""
Represents a Quantum Processing Unit (QPU).
# Fields
- `manufacturer::String` -- QPU manufacturer (e.g. "anyon")
- `generation::String` -- QPU generation (e.g. "yukon")
- `serial_number::String` -- QPU serial_number (e.g. "ANYK202201")
- `host::String` -- the remote host url address to send the jobs to
- `qubit_count::Int` -- number of physical qubits on the machine
- `connectivity::SparseArrays.SparseMatrixCSC{Int}`
- `native_gates::Vector{String}` -- the vector of native gate symbols supported by the QPU architecture
```
"""
Base.@kwdef struct QPU
    manufacturer::String
    generation::String
    serial_number::String
    host::String
    qubit_count::Int
    connectivity::SparseArrays.SparseMatrixCSC{Int}
    native_gates::Vector{String}
end

function Base.show(io::IO, qpu::QPU)
    println(io, "Quantum Processing Unit:")
    println(io, "   manufacturer: $(qpu.manufacturer)")
    println(io, "   generation: $(qpu.generation) ")
    println(io, "   serial_number: $(qpu.serial_number) ")
    println(io, "   host: $(qpu.host) ")
    println(io, "   qubit_count: $(qpu.qubit_count) ")
    println(io, "   native_gates: $(qpu.native_gates) ")
    println(io, "   connectivity = $(qpu.connectivity)")
end

"""
    create_virtual_qpu(qubit_count::UInt32, native_gates::Array{String}, host = "localhost:5600")

Creates a virtual quantum processor with `qubit_count` number of qubits and `native_gates`. 
The return value is QPU stucture (see [`QPU`](@ref)).

# Examples
```jldoctest
julia> qpu = create_virtual_qpu(3,["x" "ha"])
Quantum Processing Unit:
   manufacturer: none
   generation: none 
   serial_number: 00 
   host: localhost:5600 
   qubit_count: 3 
   native_gates: ["x" "ha"] 
```
"""
function create_virtual_qpu(qubit_count::Int, connectivity::Matrix{Int}, native_gates::Vector{String}, host = "localhost:5600")
    return create_virtual_qpu(qubit_count, SparseArrays.sparse(connectivity), native_gates, host)
end

function create_virtual_qpu(qubit_count::Int, connectivity::SparseArrays.SparseMatrixCSC{Int}, native_gates::Vector{String}, host = "localhost:5600")
    return QPU(
        manufacturer = "none",
        generation = "none",
        serial_number = "00",
        host = host,
        native_gates = native_gates,
        qubit_count = qubit_count,
        connectivity = connectivity
    )
end


function is_circuit_native_on_qpu(c::QuantumCircuit, qpu::QPU)
    for step in c.pipeline
        for gate in step
            if !(gate.instruction_symbol in qpu.native_gates)
                return false, gate.instruction_symbol
            end
        end
    end
    return true, nothing
end

function does_circuit_satisfy_qpu_connectivity(c::QuantumCircuit, qpu::QPU)
    #this function makes sure all gates satisfy the qpu connectivity
    connectivity_dense = Array(qpu.connectivity)# TODO: all operations should be done in Sparse matrix format.
    for step in c.pipeline
        for gate in step
            i_row = gate.target[1]
            for target_qubit in gate.target
                if (connectivity_dense[i_row,target_qubit]==0)
                    return false, gate
                end
            end
        end
    end        
    return true, nothing
end