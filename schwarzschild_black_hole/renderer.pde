public class BlackHoleRenderer{

    // renderer parameters

    public int      render_width,
                    render_height;

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

    // defining basis vectors
    private final PVector e_x = new PVector(1.0, 0.0, 0.0);
    private final PVector e_y = new PVector(0.0, 1.0, 0.0);
    private final PVector e_z = new PVector(0.0, 0.0, 1.0);

    /*
        parameter units in this constructor
        angles: degrees (converted to radians by the constructor itself)
        lengths: schwarzschild radii
    */
    BlackHoleRenderer(
        int render_width,
        int render_height,
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
        String acc_disk_image_path,
        String bh_shader_path,
        String render_dir
    ) {
        this.render_width = render_width;
        this.render_height = render_height;

        this.fov = radians(fov);
        this.black_hole_distance = black_hole_distance;
        this.black_hole_angle = black_hole_angle;
        
        this.max_angle = radians(max_angle);
        this.dphi = radians(dphi);
        
        this.acc_disk_min_dist = acc_disk_min_dist;
        this.acc_disk_max_dist = acc_disk_max_dist;

        this.black_hole_shader = loadShader(bh_shader_path);

        this.sky = loadImage(sky_image_path);
        this.acc_disk = loadImage(acc_disk_image_path);

        this.render_dir = render_dir;

        acc_disk_normal = new PVector(0.0, 1.0, 0.0);
        acc_disk_ref = new PVector(0.0, 0.0, 1.0);

        rot_x = radians(rot_x);
        rot_y = radians(rot_y);
        rot_z = radians(rot_z);

        acc_disk_normal = rotateUsingEulerAngles(acc_disk_normal, rot_x, rot_y, rot_z);
        acc_disk_ref = rotateUsingEulerAngles(acc_disk_ref, rot_x, rot_y, rot_z);

        center = new PVector(bh_center_x, bh_center_y);

        pp_distance = render_width / (2 * tan(this.fov / 2));

        n = new PVector(center.x * render_width, center.y * render_height, pp_distance);
        n.normalize();

        updateShader();
    }

    public void updateShader(){
        black_hole_shader.set("center", (float) render_width/2, (float) render_height/2);
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

    /*
        frame_num: frame number for numbering saved images
        sky: set to true for rendering sky separately
        bh: set to true for rendering accretion disk separately
        if both sky, bh are true, they will be rendered separately
        if both are false, black hole and accretion disk will be
        rendered in one composite image.
    */
    public void renderToImage(int frame_num, boolean sky, boolean bh){

        render_texture = createGraphics(render_width, render_height, P2D);

        updateShader();

        render_texture.beginDraw();
        render_texture.fill(255);
        render_texture.noStroke();
        render_texture.shader(black_hole_shader);

        if(bh){
            black_hole_shader.set("ACC_DISK", 1);
            black_hole_shader.set("SKY", 0);
            render_texture.rect(0, 0, render_width, render_height);
            render_texture.save(render_dir + "/acc_disk/" + str(frame_num) + ".png");
        }
        if(sky){
            black_hole_shader.set("ACC_DISK", 0);
            black_hole_shader.set("SKY", 1);
            render_texture.rect(0, 0, render_width, render_height);
            render_texture.save(render_dir + "/sky/" + str(frame_num) + ".png");
        }
        if(! (sky || bh)){
            black_hole_shader.set("ACC_DISK", 1);
            black_hole_shader.set("SKY", 1);
            render_texture.rect(0, 0, render_width, render_height);
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
        rect(0, 0, render_width, render_height);
    }

    PVector rotateUsingEulerAngles(
        PVector vec,
        float theta_x,
        float theta_y,
        float theta_z
    ) {
        PVector rotated_vec = vec;
        rotated_vec = rotateAboutAxis(e_x, rotated_vec, theta_x);
        rotated_vec = rotateAboutAxis(e_y, rotated_vec, theta_y);
        rotated_vec = rotateAboutAxis(e_z, rotated_vec, theta_z);
        return rotated_vec;
    }

    public void rotateBHAboutNormal(float theta){
        acc_disk_ref = rotateAboutAxis(acc_disk_normal, acc_disk_ref, theta);
    }

    PVector rotateAboutAxis(PVector axis, PVector vec, float theta){
        // dont change this cause it just works.
        PVector term1, term2, term3;
        term1 = term2 = term3 = new PVector(0.0, 0.0, 0.0);
        term1 = PVector.mult(axis, PVector.dot(axis, vec));
        PVector.cross(axis, vec, term2);
        PVector.cross(term2, axis, term2);
        term2 = PVector.mult(term2, cos(theta));
        PVector.cross(axis, vec, term3);
        term3 = PVector.mult(term3, sin(theta));
        return (term1.add(term2)).add(term3);
    }

}