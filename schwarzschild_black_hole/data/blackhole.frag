precision mediump float;

uniform float pp_distance;
uniform float u0;
uniform float acc_min_u;
uniform float acc_max_u;
uniform float dphi;
uniform int NSTEPS;
uniform int ACC_DISK;
uniform int SKY;

uniform vec2 center;

uniform vec3 n;
uniform vec3 acc_disk_normal;
uniform vec3 acc_disk_ref;

uniform sampler2D acc_disk_texture;
uniform sampler2D sky_texture;

float INV_TWO_PI = 0.159154943091895;
float INV_PI = 0.3183098861837906715;

vec4 get_sky_pixel(vec3 dir, sampler2D tex){
    vec3 dir_proj_x = vec3(dir.x, 0, dir.z);
    float proj_length = length(dir_proj_x);
    if(proj_length != 0.0){
        dir_proj_x = normalize(dir_proj_x);
    }
    vec2 uv;
    uv.x = (acos(-dir_proj_x.z) * sign(dir_proj_x.x) * INV_TWO_PI) + 0.5;
    uv.y = (asin(dir.y) * INV_PI) + 0.5;
    return texture2D(tex, uv);
}

float u2_d(float u1){
    return -u1 * (1.0 - (1.5 * u1 * u1));
}

void main(void){
    float m = 1.0 / (acc_min_u - acc_max_u);
    float c = -m * acc_max_u;
    vec3 color = vec3(0.0, 0.0, 0.0);
    float alpha = 0.0;
    int i;
    
    float u1 = u0;
    float phi = 0.0;

    vec3 d0 = normalize(vec3(gl_FragCoord.xy - center, -pp_distance));
    vec3 t = cross(cross(n ,d0), n);
    float t_mag = length(t);
    if(t_mag == 0.0){
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    t = t / t_mag;
    float u2 = -u1 * dot(d0, n) / dot(d0, t);

    vec3 ray_dir = n;
    vec3 p_ray_dir = ray_dir;
    float p_ray_dot = dot(ray_dir, acc_disk_normal);
    float ray_dot;

    float k11, k12, k21, k22, k13, k23, k14, k24;

    for(i = 0; i < NSTEPS; i++){
        
        k11 = dphi * (u2);
        k21 = dphi * u2_d(u1);
        k12 = dphi * (u2 + (0.5 * k21));
        k22 = dphi * u2_d(u1 + (0.5 * k11));
        k13 = dphi * (u2 + (0.5 * k22));
        k23 = dphi * u2_d(u1 + (0.5 * k12));
        k14 = dphi * (u2 + k23);
        k24 = dphi * u2_d(u1 + k13);
        u1 += (k11 + (2.0 * k12) + (2.0 * k13) + k14) / 6.0;
        u2 += (k21 + (2.0 * k22) + (2.0 * k23) + k24) / 6.0;
        phi += dphi;

        if(u1 > 1.0){
            gl_FragColor = vec4(mix(vec3(0, 0, 0), color, alpha), 1.0);
            return;
        }
        
        
        if(ACC_DISK == 1){
            ray_dir = ((n * cos(phi)) + (t * sin(phi)));
            ray_dot = dot(ray_dir, acc_disk_normal);
            if(p_ray_dot * ray_dot < 0.0){
                if(u1 > acc_min_u && u1 < acc_max_u){
                    float angle = (acos(dot(ray_dir, acc_disk_ref)) * INV_TWO_PI) + 0.5;
                    vec4 acc_pixel = texture2D(acc_disk_texture, vec2(angle, (m * u1) + c));
                    alpha = acc_pixel.a;
                    color += acc_pixel.rgb;
                }
            }
            p_ray_dir = ray_dir;
            p_ray_dot = ray_dot;
        }

        if(u1 < 0.0){
            break;
        }
        
    }

    if(SKY == 1){
        color += get_sky_pixel((n * cos(phi)) + (t * sin(phi)), sky_texture).rgb;
        gl_FragColor = vec4(color, 1.0);
    }else{
        gl_FragColor = vec4(color, alpha);
    }
    
}