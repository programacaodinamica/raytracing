using Images
using ProgressMeter
include("vector.jl")

# IMAGE
aspectratio = 16 / 9
imwidth = 800
imheight = trunc(Int64, imwidth / aspectratio)

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
    (1.0-t) * RGB(1.0, 1.0, 1.0) + t * RGB(0.5, 0.7, 1.0)
end

function marscolor(dir)
    t = 0.5 * (dir[2] + 1.0)
    (1-t)RGB(0.9, 0.8, 0.7) + t*RGB(0.2, 0.05, 0.05)
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

s1 = Sphere(Vec3(0.0, 0.0, -1.0), 0.5, Metal(RGB(1.0, 1.0, 1.0)))
# s2 = Sphere(Vec3(-1.0, 0.0, -2.0), 0.5)
# s3 = Sphere(Vec3(0.5, 1.5, -1.5), 0.5)
# s4 = Sphere(Vec3(2.5, 0.2, -1.0), 0.5)
bigradius = 100.0
floor = Sphere(Vec3(0.0, -bigradius - 0.5, -1.0), 
                bigradius, Metal(RGB(0.0, 0.5, 0.0)))

world = SceneList()
push!(world, s1)
# push!(world, s2)
# push!(world, s3)
# push!(world, s4)
push!(world, floor)

function render(samples_perpixel=100, maxdepth=50)
    image = RGB.(zeros(imheight, imwidth))
    @showprogress 1 "Computing..." for j = 1:imheight
        for i = 1:imwidth
            pixelcolor = RGB(0.0, 0.0, 0.0)
            for n = 1:samples_perpixel
                u = (i - 1 + rand()) / (imwidth - 1)
                v = 1.0 - (j - 1 + rand()) / (imheight - 1)
                dir = lowerleftcorner + u*horizontal + v*vertical - origin
                ray = Ray(origin, dir)
                pixelcolor += raycolor(ray, world, maxdepth)
            end
            image[j, i] = pixelcolor / samples_perpixel
        end
    end   
    image
end

frame = render(100)
save("rendered/imagem10.png", frame)

