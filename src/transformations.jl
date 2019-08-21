#####
##### transformations
#####

####
#### linear transformation
####

struct Linear{L,M,S,T} <: SamplingLogDensity
    ℓ::L
    A::M
    divA::S
    logabsdetA::T
end

"""
$(SIGNATURES)

Internal method for returning an object that makes `A \\ x` fast and stable.
"""
_fastdiv(A::AbstractMatrix) = lu(A)
_fastdiv(A::AbstractTriangular) = A
_fastdiv(A::Diagonal) = A

"""
$(SIGNATURES)

Internal method for logabsdet, work around
https://github.com/JuliaLang/julia/issues/32988
"""
_logabsdet(A::AbstractMatrix) = first(logabsdet(A))
_logabsdet(A::Diagonal) = sum(log ∘ abs, diag(A))

"""
$(SIGNATURES)

Transform a distribution on `x` to `y = Ax`, where `A` is a conformable square matrix.

Since the log Jacobian is constant, it is dropped in the log density.
"""
function linear(A::AbstractMatrix, ℓ)
    K = dimension(ℓ)
    @argcheck checksquare(A) == K
    Linear(ℓ, A, _fastdiv(A), _logabsdet(A))
end

dimension(ℓ::Linear) = dimension(ℓ.ℓ)

logdensity(ℓ::Linear, x) = logdensity(ℓ.ℓ, ℓ.divA \ x) - ℓ.logabsdetA

function logdensity_and_gradient(ℓ::Linear, x)
    f, ∇f = logdensity_and_gradient(ℓ.ℓ, ℓ.divA \ x)
    f - ℓ.logabsdetA, (ℓ.divA') \ ∇f
end

hypercube_transform(ℓ::Linear, x) = ℓ.A * hypercube_transform(ℓ.ℓ, x)

####
#### shift (translation)
####

struct Shift{L, T <: AbstractVector} <: SamplingLogDensity
    ℓ::L
    b::T
end

"""
$(SIGNATURES)

Transform a distribution on `x` to `y = x + b`, where `b` is a conformable vector.
"""
function shift(b::AbstractVector, ℓ)
    @argcheck length(b) == dimension(ℓ)
    Shift(ℓ, b)
end

dimension(ℓ::Shift) = dimension(ℓ.ℓ)

logdensity(ℓ::Shift, x) = logdensity(ℓ.ℓ, x - ℓ.b)

# The log Jacobian adjustment is zero
logdensity_and_gradient(ℓ::Shift, x) = logdensity_and_gradient(ℓ.ℓ, x - ℓ.b)

hypercube_transform(ℓ::Shift, x) = ℓ.b .+ hypercube_transform(ℓ.ℓ, x)
