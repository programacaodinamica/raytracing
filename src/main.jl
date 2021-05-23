using Images
using ProgressMeter
using LinearAlgebra

include("vector.jl")

# IMAGE
aspectratio = 16 / 9
imwidth = 800
imheight = trunc(Int64, imwidth / aspectratio)


struct Camera
    # origin
    lookfrom::Vec3
    horizontal::Vec3
    vertical::Vec3
    lowerleftcorner::Vec3
    lensradius::AbstractFloat
    u::Vec3
    v::Vec3
    w::Vec3

    function Camera(vfov, lookfrom::Vec3, lookat::Vec3, up::Vec3, 
                    aperture=0.0, focus_dist=1.0)
        
        w = unitvector(lookfrom - lookat)
        u = unitvector(cross(up, w))
        v = cross(w, u)

        θ = deg2rad(vfov)
        h = tan(θ/2)
        viewportheight = 2.0 * h
        viewportwidth = viewportheight * aspectratio

        horizontal = u * viewportwidth * focus_dist
        vertical = v * viewportheight * focus_dist

        lensradius = aperture/2
        
        lowerleftcorner = lookfrom - horizontal/2 - vertical/2 - w * focus_dist
        new(lookfrom, horizontal, vertical, lowerleftcorner, 
        lensradius, u, v, w)
    end
end

function random_indisc()
    θ = rand(0.0:0.001:2*π)
    Vec3(cos(θ), sin(θ), 0.0)
end

function getray(camera, s, t)
    hor = camera.horizontal
    vert = camera.vertical

    rd = camera.lensradius * random_indisc()

    origin = camera.lookfrom + camera.u * rd[1] + camera.v * rd[2]
    dir = camera.lowerleftcorner + s*hor + t*vert - origin
    Ray(origin, dir)
end

println("Image size $imwidth x $imheight")

function backgroundcolor(dir)
    t = 0.5 * (dir[2] + 1.0)
    (1.0-t) * RGB(1.0, 1.0, 1.0) + t * RGB(0.5, 0.7, 1.0)
end

function marscolor(dir)
    t = 0.5 * (dir[2] + 1.0)
    (1-t)RGB(0.9, 0.8, 0.7) + t*RGB(0.2, 0.05, 0.05)
end

function gammacorrection(c::RGB)
    color = sqrt.([c.r, c.g, c.b])
    RGB(color...)
end

clamp(value::AbstractFloat, vmin=0.0, vmax=1.0) = min(max(value, vmin), vmax)

function clamp(color::RGB, vmin=0.0, vmax=1.0)
    res = clamp.([color.r, color.g, color.b], vmin, vmax)
    RGB(res...)
end

function raycolor(ray::Ray, scenelist::SceneList, depth::Int)
    record = HitRecord()

    if depth ≤ 0
        return RGB(0.0, 0.0, 0.0)
    end
    if hit!(scenelist, ray, 0.0001, Inf, record)

        # preciso saber se devo lançar um novo raio
        shouldscatter, attenuation, direction = scatter(record.material, ray, record)
        if shouldscatter
            # saber que cor está atenuando
            newray = Ray(record.p, direction)
            return attenuation * raycolor(newray, scenelist, depth-1)
        else
            return RGB(0.0 , 0.0, 0.0)
        end   
    end
    
    backgroundcolor(ray.direction)
end

materialfloor = Lambertian(RGB(0.8, 0.8, 0.0))
materialcenter = Lambertian(RGB(0.1, 0.2, 0.5))
materialleft = Metal(RGB(0.8, 0.8, 0.8), 0.3)
materialright  = Metal(RGB(0.8, 0.6, 0.2), 1.0)

glass = Dieletric(1.5)

s1 = Sphere(Vec3(0.0, 0.0, -1.0), 0.5, materialcenter)
s2 = Sphere(Vec3(-1.0, 0.0, -1.0), 0.5, glass)
s4 = Sphere(Vec3(-1.0, 0.0, -1.0), -0.4, glass)
s3 = Sphere(Vec3(1.0, 0.0, -1.0), 0.5, materialright)

bigradius = 100.0
floor = Sphere(Vec3(0.0, -bigradius - 0.5, -1.0), 
                bigradius, materialfloor)

world = SceneList()
push!(world, s1)
push!(world, s2)
push!(world, s3)
push!(world, s4)
push!(world, floor)

lookfrom = Vec3(0.0, 0.0, 0.0)
lookat = Vec3(0.0, 0.0, -1.0)
up = Vec3(0.0, 1.0, 0.0)
camera = Camera(90, lookfrom, lookat, up, 0.0, norm(lookfrom - lookat))

function render(samples_perpixel=100, maxdepth=50)
    image = RGB.(zeros(imheight, imwidth))
    @showprogress 1 "Computing..." for j = 1:imheight
        for i = 1:imwidth
            pixelcolor = RGB(0.0, 0.0, 0.0)
            for n = 1:samples_perpixel
                u = (i - 1 + rand()) / (imwidth - 1)
                v = 1.0 - (j - 1 + rand()) / (imheight - 1)
                ray = getray(camera, u, v)
                pixelcolor += raycolor(ray, world, maxdepth)
            end
            image[j, i] = clamp(pixelcolor / samples_perpixel)
        end
    end   
    gammacorrection.(image)
end

frame = render(100)
save("rendered/imagem22.png", frame)

