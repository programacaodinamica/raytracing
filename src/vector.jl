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

function rayat(ray::Ray, t)
    ray.origin + t * ray.direction
end



struct Sphere{T <: AbstractFloat}
    center::Vec3{T}
    radius::T

    function Sphere{T}(c::Vec3{T}, r::T) where T
        new(c, r)    
    end
end

function Sphere(c::Vec3{T}, r::T) where T
    Sphere{T}(c, r)
end

function hit(sphere::Sphere, ray::Ray)
    # bhaskara
    oc = ray.origin - sphere.center
    a = normsquared(ray.direction)
    halfb = dot(ray.direction, oc)
    c = normsquared(oc) - sphere.radius^2
    discriminant = halfb*halfb - a*c

    if discriminant < 0
        - 1.0
    else
        (-halfb - √discriminant) / a
    end
end