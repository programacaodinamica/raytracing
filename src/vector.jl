import Base.push!
import Base.*

abstract type Material end

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

abstract type SceneObject 
end

mutable struct HitRecord{T <: AbstractFloat}
    p::Vec3{T}
    t::T
    normal::Vec3{T}
    frontface::Bool
    material::Material

    function HitRecord{T}(p::Vec3{T}, t::T, n::Vec3{T}) where T <: AbstractFloat
        new(p, t, n, false, Metal(RGB(0.0, 0.0, 0.0), 0.0))
    end
end

function HitRecord(p::Vec3{T}, t::T, n::Vec3{T}) where T <: AbstractFloat
    HitRecord{T}(p, t, n)
end

function HitRecord()
    HitRecord(Vec3(0.0, 0.0, 0.0), 0.0, Vec3(0.0, 0.0, 0.0))
end

struct SceneList <: SceneObject
    objects::Vector{SceneObject}

    function SceneList(objs::Vector{SceneObject})
        new(objs)
    end
end

SceneList() = SceneList(Vector{SceneObject}())

function push!(scenelist::SceneList, object::SceneObject)
    push!(scenelist.objects, object)
end

struct Sphere{T <: AbstractFloat} <: SceneObject
    center::Vec3{T}
    radius::T
    material::Material

    function Sphere{T}(c::Vec3{T}, r::T, mat::Material) where T
        new(c, r, mat)    
    end
end

function Sphere(c::Vec3{T}, r::T, mat::Material) where T
    Sphere{T}(c, r, mat)
end

function hit!(sphere::Sphere, ray::Ray, t_min, t_max, record::HitRecord)
    # bhaskara
    oc = ray.origin - sphere.center
    a = normsquared(ray.direction)
    halfb = dot(ray.direction, oc)
    c = normsquared(oc) - sphere.radius^2
    discriminant = halfb*halfb - a*c

    if discriminant < 0
        return false
    else
        sqrd = √discriminant
        t = (-halfb - sqrd) /a
        if t < t_min || t > t_max
            t = (-halfb + sqrd) /a
            if t < t_min || t > t_max
                return false
            end
        end
        record.t = t
        record.p = rayat(ray, t)
        outward_normal = (record.p - sphere.center) / sphere.radius
        record.frontface = dot(ray.direction, outward_normal) < 0
        record.normal = record.frontface ? outward_normal : -outward_normal
        record.material = sphere.material
        true
    end
end

function hit!(scenelist::SceneList, ray::Ray, t_min, t_max, record::HitRecord)
    hitanything = false
    temprecord = HitRecord()
    closestsofar = t_max

    for object in scenelist.objects
        if hit!(object, ray::Ray, t_min, closestsofar, temprecord)
            hitanything = true
            closestsofar = temprecord.t

            record.p = temprecord.p
            record.t = temprecord.t
            record.normal = temprecord.normal
            record.frontface = temprecord.frontface
            record.material = temprecord.material
        end
    end

    hitanything
end

function reflect(dir::Vec3, normal::Vec3)
    dir -  2.0 * dot(dir, normal) * normal
end


struct Metal <: Material
    albedo::RGB
    fuzz::Float64
end

function scatter(material::Metal, ray::Ray, record::HitRecord)
    reflecteddir = reflect(ray.direction, record.normal) + material.fuzz * random_insphere()
    shouldscatter = dot(reflecteddir, record.normal) > 0
    shouldscatter, material.albedo, reflecteddir
end


function *(c1::RGB, c2::RGB)
    RGB(c1.r*c2.r, c1.g*c2.g, c1.b*c2.b)
end

struct Lambertian <: Material
    albedo::RGB
end

function random_unitvector()
    θ = rand(0.0:0.001:2*π)
    ϕ = rand(0.0:0.001:π)
    Vec3(cos(θ)*sin(ϕ), sin(θ)*sin(ϕ), cos(ϕ))
end

function random_insphere()
    θ = rand(0.0:0.001:2*π)
    ϕ = rand(0.0:0.001:π)
    r = rand()
    r * Vec3(cos(θ)*sin(ϕ), sin(θ)*sin(ϕ), cos(ϕ))
end

function scatter(material::Lambertian, ray::Ray, record::HitRecord)
    scatterdir = record.normal + random_unitvector()
    if all(map( x -> isapprox(x, 0; atol=1e-8), scatterdir))
        scatterdir = record.normal
    end
    
    true, material.albedo, scatterdir
end

struct Dieletric <: Material
    refraction_index::AbstractFloat
end

function refract(dir::Vec3, normal::Vec3, refractionratio)
    cosθ = dot(-dir, normal)
    perp = refractionratio * (dir + cosθ*normal)
    parallel = - sqrt(1 - normsquared(perp)) * normal
    perp + parallel
end

function reflectance(cosine, refidx)
    # Use Schlick's approximation for reflectance.
    r0 = (1-refidx) / (1+refidx)
    r0 = r0*r0
    r0 + (1-r0)*((1 - cosine)^5)
end

function scatter(material::Dieletric, ray::Ray, record::HitRecord)
    ir = material.refraction_index
    refractionratio = record.frontface ? 1.0/ir : ir

    cosθ = dot(-ray.direction, record.normal)
    sinθ = sqrt(1 - cosθ^2)

    cannotrefract = refractionratio * sinθ > 1.0

    scatterdir = if cannotrefract || reflectance(cosθ, refractionratio) > rand()
        reflect(ray.direction, record.normal)
    else
        refract(ray.direction, record.normal, refractionratio)
    end
    
    true, RGB(1.0, 1.0, 1.0), scatterdir
end