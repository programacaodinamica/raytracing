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

function raycolor(ray::Ray)
    t = 0.5 * (ray.direction[2] + 1.0)
    (1-t)RGB(1.0, 1.0, 1.0) + t*RGB(0.5, 0.7, 1.0)
end

for j = 1:imheight
    for i = 1:imwidth
        u = (i - 1) / (imwidth - 1)
        v = 1.0 - (j - 1) / (imheight - 1)
        dir = lowerleftcorner + u*horizontal + v*vertical - origin
        ray = Ray(origin, dir)
        image[j, i] = raycolor(ray)
    end
end

save("rendered/imagem1.png", image)

