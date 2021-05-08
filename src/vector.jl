const Vec3{T <: Real} = Array{T, 1}

function Vec3{T}(x::T, y::T, z::T) where T
    [x, y, z]
end

function Vec3(x::T, y::T, z::T) where T
    Vec3{T}(x, y, z)
end

normsquared(vector::Vec3) = sum(map(x -> x^2, vector))

norm(vector::Vec3) = √normsquared(vector)

dot(v1::Vec3, v2::Vec3) = sum(v1 .* v2)

unitvector(v) = v / norm(v)


struct Ray{T <: AbstractFloat}
    origin::Vec3{T}
    direction::Vec3{T}

    function Ray{T}(orgn::Vec3{T}, dir::Vec3{T}) where T
        new(orgn, unitvector(dir))
    end
end

function Ray(orgn::Vec3{T}, dir::Vec3{T}) where T
    Ray{T}(orgn, dir)
end


raio = Ray(Vec3(1.0, 2.0, 3.0), Vec3(7.0, 0.0, 0.0))