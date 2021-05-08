using Images

imwidth = 800
imheight = 600

image = RGB.(zeros(imheight, imwidth))

for j = 1:imheight
    for i = 1:imwidth
        r = (i - 1) / (imwidth - 1)
        g = 1.0 - (j - 1) / (imheight - 1)
        b = 0.25

        image[j, i] = RGB(r, g, b)
    end
end

save("rendered/imagem0.png", image)

