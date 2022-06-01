using Snowflake
using Test

function canonicalize_operator_global_phase(matrix::Matrix{Complex})::Matrix{Complex}
    for element in matrix
        if abs(element) > 1e-6
            return exp(-im * angle(element)) .* matrix
        end
    end

    error("an operator cannot be a zero matrix")
end

function is_gate_equal_up_to_global_rotation(gate::Gate, matrix::Matrix{Complex})::Bool
    gate_matrix = canonicalize_operator_global_phase(gate.operator.data)
    matrix = canonicalize_operator_global_phase(matrix)
    cmp(ab) = isapprox(real(ab[1]), real(ab[2]), atol = 1e-8) && isapprox(imag(ab[1]), imag(ab[2]), atol = 1e-8)
    equals = map(cmp, zip(gate_matrix, matrix))
    return all(equals)
end


@testset "gate_set" begin
    H = hadamard(1)

    @test H.instruction_symbol == "h"
    @test H.display_symbol == ["H"]

    X = sigma_x(1)
    @test X.instruction_symbol == "x"
    @test X.display_symbol == ["X"]
    @test is_gate_equal_up_to_global_rotation(X, convert(Matrix{Complex}, [[0.0im, 1.0] [1.0, 0.0]]))

    Y = sigma_y(1)
    @test Y.instruction_symbol == "y"
    @test Y.display_symbol == ["Y"]
    @test is_gate_equal_up_to_global_rotation(Y, convert(Matrix{Complex}, [[0.0im, -1.0im] [1.0im, 0.0]]))

    Z = sigma_z(1)
    @test Z.instruction_symbol == "z"
    @test Z.display_symbol == ["Z"]

    CX = control_x(1, 2)
    @test CX.instruction_symbol == "cx"

    CZ = control_z(1, 2)
    @test CZ.instruction_symbol == "cz"

    ψ_0 = fock(0, 2)
    ψ_1 = fock(1, 2)

    S = phase(1)
    @test S.instruction_symbol == "s"
    @test S * ψ_0 ≈ ψ_0
    @test S * ψ_1 ≈ im * ψ_1

    T = pi_8(1)
    @test T.instruction_symbol == "t"
    @test T * ψ_0 ≈ ψ_0
    @test T * ψ_1 ≈ exp(im * pi / 4.0) * ψ_1

    X90 = x_90(1)
    @test X90.instruction_symbol == "x_90"
    @test is_gate_equal_up_to_global_rotation(
        X90,
        convert(
            Matrix{Complex},
            [[1.0 / sqrt(2.0), -im / sqrt(2.0)] [-im / sqrt(2.0), 1.0 / sqrt(2.0)]]
        )
    )

    Xm90 = x_minus_90(1)
    @test Xm90.instruction_symbol == "x_minus_90"
    @test is_gate_equal_up_to_global_rotation(
        Xm90,
        convert(
            Matrix{Complex},
            [[1.0 / sqrt(2.0), im / sqrt(2.0)] [im / sqrt(2.0), 1.0 / sqrt(2.0)]]
        )
    )

    Y90 = y_90(1)
    @test Y90.instruction_symbol == "y_90"
    @test is_gate_equal_up_to_global_rotation(
        Y90,
        convert(
            Matrix{Complex},
            [[1.0 / sqrt(2.0), -1.0 / sqrt(2.0)] [1.0 / sqrt(2.0), 1.0 / sqrt(2.0)]]
        )
    )

    Ym90 = y_minus_90(1)
    @test Ym90.instruction_symbol == "y_minus_90"
    @test is_gate_equal_up_to_global_rotation(
        Ym90,
        convert(
            Matrix{Complex},
            [[1.0 / sqrt(2.0), 1.0 / sqrt(2.0)] [-1.0 / sqrt(2.0), 1.0 / sqrt(2.0)]]
        )
    )

end

@testset "gate_set_exceptions" begin
    @test_throws DomainError control_x(1, 1)
end

@testset "tensor_product_single_qubit_gate" begin


    Ψ1_0 = fock(0, 2) # |0> for qubit_1
    Ψ1_1 = fock(1, 2) # |1> for qubit_1
    Ψ2_0 = fock(0, 2) # |0> for qubit_2
    Ψ2_1 = fock(1, 2) # |0> for qubit_2
    ψ_init = kron(Ψ1_0, Ψ2_0)

    U = kron(sigma_x(), eye())
    @test U * ψ_init ≈ kron(Ψ1_1, Ψ2_0)

    U = kron(eye(), sigma_x())
    @test U * ψ_init ≈ kron(Ψ1_0, Ψ2_1)

    U = kron(sigma_x(), sigma_x())
    @test U * ψ_init ≈ kron(Ψ1_1, Ψ2_1)

end

@testset "std_gates" begin
    std_gates = ["x", "y", "z", "s", "t", "i", "h", "cx", "cz", "iswap"]
    for gate in std_gates
        @test gate in keys(STD_GATES)
    end
end

@testset "pauli_gates" begin
    pauli_gates = ["x", "y", "z", "i"]
    for gate in pauli_gates
        @test gate in keys(STD_GATES)
    end
end
