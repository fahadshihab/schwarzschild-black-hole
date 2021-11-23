from scipy.linalg import norm
from scipy.interpolate import interp2d
from scipy.integrate import ode
import numpy, time
from PIL import Image

def black_hole_equation(phi, u):
    u1, u2 = u
    return [u2, -u1 * (1 - (1.5 * u1 * u1))]


# default black hole parameters
RESOLUTION = [200, 200]
BLACK_HOLE_POSITION = [0, 0, -30]

FOV = numpy.radians(60)

dphi = 0.01

pp_distance = RESOLUTION[0] / (2 * numpy.tan(FOV / 2))
camera_pos = -1 * numpy.array(BLACK_HOLE_POSITION)
n = camera_pos / norm(camera_pos)

total_rays = RESOLUTION[0] * RESOLUTION[1]

u_0 = [1 / norm(camera_pos), 0]

out_image = Image.new("RGB", tuple(RESOLUTION), (100, 0, 0))

out_image_data = numpy.asarray(out_image)

with Image.open("textures/sky_bg.jpg") as sky_bg:
    sky = sky_bg.load()

def get_sky_pixel(dir, texture, texturePixels):
    dir_proj_x = numpy.array([dir[0], 0, dir[2]])
    try:
        dir_proj_x = dir_proj_x / norm(dir_proj_x)
    except ValueError:
        dir_proj_x = [0, 0, 0]
    
    azimuth = numpy.arccos(-dir_proj_x[2]) * numpy.sign(dir_proj_x[0])
    elevation = numpy.arcsin(dir[1])
    pixel_x = (texture.width / (2 * numpy.pi) * azimuth) + (texture.width / 2)
    pixel_y = - (texture.height / numpy.pi * elevation) + (texture.height / 2)
    pixel_coord = [pixel_x, pixel_y]
    
    interp_table_x = [numpy.floor(pixel_x), numpy.ceil(pixel_x)]
    interp_table_y = [numpy.floor(pixel_y), numpy.ceil(pixel_y)]

    try:
        interp_table_pixels = numpy.array([[list(texturePixels[i, j]) for i in interp_table_x] for j in interp_table_y])
    except:
        interp_table_pixels = numpy.array([[texturePixels[0, 0], texturePixels[0, 0]], [texturePixels[0, 0], texturePixels[0, 0]]])
    def interpolate(x, y, z, t):
        x_matrix = numpy.array([x[1] - t[0], t[0] - x[0]])
        y_matrix = numpy.array([y[1] - t[1], t[1] - y[0]]).T
        multiplier = ((x[1] - x[0]) * (y[1] - y[0]))
        if(multiplier == 0):
            return z[0, 0]
        return numpy.matmul((x_matrix / multiplier), numpy.matmul(z, y_matrix))

    interpolated_pixel_color = [int(interpolate(interp_table_x, interp_table_y, interp_table_pixels[:, :, 0], pixel_coord)),
                                int(interpolate(interp_table_x, interp_table_y, interp_table_pixels[:, :, 1], pixel_coord)),
                                int(interpolate(interp_table_x, interp_table_y, interp_table_pixels[:, :, 2], pixel_coord))]
    
    return tuple(interpolated_pixel_color)
    


raytracing_start_time = time.time()

for i in range(0, RESOLUTION[0]):
    for j in range(0, RESOLUTION[1]):

        d_0 = numpy.array([i - (RESOLUTION[0] / 2), (RESOLUTION[1] / 2) - j, -pp_distance])
        d_0 = d_0 / norm(d_0)

        t = numpy.cross(numpy.cross(n, d_0), n)
        t = t / norm(t)

        u_0[1] = -u_0[0] * numpy.dot(d_0, n) / numpy.dot(d_0, t)
        u = u_0

        integrator = ode(black_hole_equation).set_integrator('zvode', method='bdf')
        integrator.set_initial_value(u_0, 0)
        
        while (integrator.successful() and u[0] > 0):
            u = integrator.integrate(integrator.t + dphi)
            ray_pos = numpy.add(numpy.cos(integrator.t) * n, numpy.sin(integrator.t) * t) / u[0]


        raytraced = (i * RESOLUTION[0]) + j
        
        try:
            ETA = (total_rays - raytraced) * (time.time() - raytracing_start_time) / raytraced
            # ETA = (i * RESOLUTION[0] + j) / (time.time() - raytracing_start_time)
        except ZeroDivisionError:
            ETA = numpy.infty
        print("raytraced " + str(raytraced) + " of " + str(total_rays) + " ETA = " + str(numpy.floor(ETA / 6) / 10) + " mins                  ", end="\r")
        
        if (not integrator.successful()):
            out_image.putpixel((i, j), (0, 0, 0))
            continue

        ray_final_dir = (numpy.cos(integrator.t) * n) + (numpy.sin(integrator.t) * t)

        try:
            skyPixel = get_sky_pixel(ray_final_dir, sky_bg, sky)
        except:
            skyPixel = (0, 0, 0)

        out_image.putpixel((i, j), skyPixel)


out_image.save("out/blackholeimage.jpg")