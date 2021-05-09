using Images
include("vector.jl")

# IMAGE
aspectratio = 16 / 9
imwidth = 800
imheight = trunc(Int64, imwidth / aspectratio)
image = RGB.(zeros(imheight, imwidth))

# CAMERA
viewportheight = 2.0
viewportwidth = viewportheight * aspectratio
horizontal = Vec3(viewportwidth, 0.0, 0.0)
vertical = Vec3(0.0, viewportheight, 0.0)
focallenght = 1.0
origin = Vec3(0.0, 0.0, 0.0)
lowerleftcorner = origin - horizontal/2 - vertical/2 - Vec3(0.0, 0.0, focallenght)

println("Image size $imwidth x $imheight")

function backgroundcolor(dir)
    t = 0.5 * (dir[2] + 1.0)
    (1-t)RGB(0.7, 0.8, 0.9) + t*RGB(0.05, 0.05, 0.2)
end

function marscolor(dir)
    t = 0.5 * (dir[2] + 1.0)
    (1-t)RGB(0.9, 0.8, 0.7) + t*RGB(0.2, 0.05, 0.05)
end

function raycolor(ray::Ray, scenelist::SceneList)
    record = HitRecord()

    orgn = ray.origin
    dir = ray.direction
    while hit!(scenelist, Ray(orgn, dir), 0.0001, Inf, record)
        dir = unitvector(reflect(dir, record.normal))
        orgn = record.p
    end
    
    # backgroundcolor(dir)
    marscolor(dir)
end

s1 = Sphere(Vec3(0.0, 0.0, -1.5), 0.5)
s2 = Sphere(Vec3(-1.0, 0.0, -2.0), 0.5)
s3 = Sphere(Vec3(0.5, 1.5, -1.5), 0.5)
s4 = Sphere(Vec3(2.5, 0.2, -1.0), 0.5)
bigradius = 1000.0
floor = Sphere(Vec3(0.0, -bigradius - 0.5, -1.0), bigradius)

world = SceneList()
push!(world, s1)
push!(world, s2)
push!(world, s3)
push!(world, s4)
push!(world, floor)

for j = 1:imheight
    for i = 1:imwidth
        u = (i - 1) / (imwidth - 1)
        v = 1.0 - (j - 1) / (imheight - 1)
        dir = lowerleftcorner + u*horizontal + v*vertical - origin
        ray = Ray(origin, dir)
        image[j, i] = raycolor(ray, world)
    end
end

save("rendered/imagem8.png", image)

