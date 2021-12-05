public class BlackHoleRenderer{

    // renderer parameters

    public int      width,
                    height;

    public float    fov,
                    black_hole_angle,
                    black_hole_distance,
                    acc_disk_min_dist,
                    acc_disk_max_dist,
                    dphi,
                    max_angle;

    private float   pp_distance;

    private String  render_dir;
    
    private PVector n,
                    acc_disk_normal,
                    acc_disk_ref,
                    center;

    private PImage  sky,
                    acc_disk;

    private PShader black_hole_shader;

    private PGraphics render_texture;

    private final PVector e_x = new PVector(1.0, 0.0, 0.0);
    private final PVector e_y = new PVector(0.0, 1.0, 0.0);
    private final PVector e_z = new PVector(0.0, 0.0, 1.0);

    // with accretion disk
    BlackHoleRenderer(
        int width,
        int height,
        float fov,
        float black_hole_distance,
        float bh_center_x,
        float bh_center_y,
        float rot_x,
        float rot_y,
        float rot_z,
        float max_angle,
        float dphi,
        String sky_image_path,
        float acc_disk_min_dist,
        float acc_disk_max_dist,
        float black_hole_angle,
        String acc_disk_image_path,
        String bh_shader_path,
        String render_dir
    ) {
        this.width = width;
        this.height = height;

        this.fov = radians(fov);
        this.black_hole_distance = black_hole_distance;
        this.black_hole_angle = black_hole_angle;
        
        this.max_angle = radians(max_angle);
        this.dphi = dphi;
        
        this.acc_disk_min_dist = acc_disk_min_dist;
        this.acc_disk_max_dist = acc_disk_max_dist;

        this.black_hole_shader = loadShader(bh_shader_path);

        this.sky = loadImage(sky_image_path);
        this.acc_disk = loadImage(acc_disk_image_path);

        this.render_dir = render_dir;

        acc_disk_normal = new PVector(0.0, 1.0, 0.0);
        acc_disk_ref = new PVector(0.0, 0.0, 1.0);

        acc_disk_normal = rotateUsingEulerAngles(acc_disk_normal, rot_x, rot_y, rot_z);
        acc_disk_ref = rotateUsingEulerAngles(acc_disk_ref, rot_x, rot_y, rot_z);

        center = new PVector(bh_center_x, bh_center_y);

        pp_distance = width / tan(this.fov);

        n = new PVector(center.x * width, center.y * height, pp_distance);

        updateShader();
    }

    public void updateShader(){
        black_hole_shader.set("center", width/2, height/2);
        black_hole_shader.set("u0", 1.0/black_hole_distance);
        black_hole_shader.set("n", n.x, n.y, n.z);
        black_hole_shader.set("pp_distance", pp_distance);
        
        black_hole_shader.set(
            "acc_disk_normal",
            acc_disk_normal.x,
            acc_disk_normal.y,
            acc_disk_normal.z
        );
        black_hole_shader.set(
            "acc_disk_ref",
            acc_disk_ref.x,
            acc_disk_ref.y,
            acc_disk_ref.z
        );
                                                
        black_hole_shader.set("sky_texture", sky);
        black_hole_shader.set("acc_disk_texture", acc_disk);
        
        black_hole_shader.set("dphi", dphi);
        black_hole_shader.set("NSTEPS", (int) (max_angle / dphi));
        
        black_hole_shader.set("acc_min_u", 1.0 / acc_disk_max_dist);
        black_hole_shader.set("acc_max_u", 1.0 / acc_disk_min_dist);

    }

    public void renderToImage(int frame_num, boolean sky, boolean bh){

        render_texture = createGraphics(width, height, P2D);

        updateShader();

        render_texture.beginDraw();
        render_texture.fill(255);
        render_texture.noStroke();
        render_texture.shader(black_hole_shader);

        if(bh){
            black_hole_shader.set("ACC_DISK", 1);
            black_hole_shader.set("SKY", 0);
            render_texture.rect(0, 0, width, height);
            render_texture.save(render_dir + "/acc_disk/" + str(frame_num) + ".png");
        }
        if(sky){
            black_hole_shader.set("ACC_DISK", 0);
            black_hole_shader.set("SKY", 1);
            render_texture.rect(0, 0, width, height);
            render_texture.save(render_dir + "/sky/" + str(frame_num) + ".png");
        }
        if(! (sky || bh)){
            black_hole_shader.set("ACC_DISK", 1);
            black_hole_shader.set("SKY", 1);
            render_texture.rect(0, 0, width, height);
            render_texture.save(render_dir + "/together/" + str(frame_num) + ".png");
        }
        
        render_texture.endDraw();
    }

    // works only when window size equals renderer size
    public void renderToDisplay(){
        updateShader();
        black_hole_shader.set("ACC_DISK", 1);
        black_hole_shader.set("SKY", 1);
        fill(255);
        noStroke();
        shader(black_hole_shader);
        rect(0, 0, width, height);
    }

    PVector rotateUsingEulerAngles(
        PVector vec,
        float theta_x,
        float theta_y,
        float theta_z
    ) {
        PVector rotated_vec = vec;
        rotated_vec = rotateAboutAxis(rotated_vec, e_x, theta_x);
        rotated_vec = rotateAboutAxis(rotated_vec, e_y, theta_y);
        rotated_vec = rotateAboutAxis(rotated_vec, e_z, theta_z);
        return rotated_vec;
    }

    public void rotateBHAboutNormal(float theta){
        acc_disk_ref = rotateAboutAxis(acc_disk_ref, acc_disk_normal, theta);
    }

    PVector rotateAboutAxis(PVector u, PVector x, float theta){
        
        PVector term1, term2, term3;
        term1 = term2 = term3 = new PVector(0.0, 0.0, 0.0);
        term1 = PVector.mult(u, PVector.dot(u, x));
        PVector.cross(u, x, term2);
        PVector.cross(term2, u, term2);
        term2 = PVector.mult(term2, cos(theta));
        PVector.cross(u, x, term3);
        term3 = PVector.mult(term3, sin(theta));
        return (term1.add(term2)).add(term3);
    }

}