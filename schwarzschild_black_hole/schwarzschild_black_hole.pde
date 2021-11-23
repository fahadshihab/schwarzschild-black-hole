

PGraphics render_texture;
PShader black_hole_shader;
PImage sky, acc_disk;

int render_width = 4096;
int render_height = 2160;
float FOV = radians(50);
float black_hole_angle = radians(3);
float dphi = radians(0.03);
float max_angle = radians(360);
float black_hole_distance = 16;
float acc_disk_min_dist = 1.4;
float acc_disk_max_dist = 8;

PVector up, n;
PVector bh_center = new PVector(0, 0);
PVector acc_disk_normal;
PVector acc_disk_ref;
float pp_distance;


void setup(){
  size(1800, 800, P2D);
  
  up = new PVector(1.0, 0.0);
  up.rotate(black_hole_angle);
  acc_disk_normal = new PVector(0.0, up.x, up.y);
  acc_disk_ref = new PVector(0.0, -up.y, up.x);
  
  pp_distance = width / tan(FOV);
  n = new PVector(bh_center.x * width,
                  bh_center.y * height,
                  pp_distance);
  n.normalize();
  
  sky = loadImage("sky_bg.jpg");
  acc_disk = loadImage("acc_disk.png");
  
  black_hole_shader = loadShader("blackhole.frag");
  
  black_hole_shader.set("center", (float) width/2, (float) height/2);
  black_hole_shader.set("u0", 1.0 / black_hole_distance);
  black_hole_shader.set("n", n.x, n.y, n.z);
  black_hole_shader.set("pp_distance", pp_distance);
  
  black_hole_shader.set("acc_disk_normal", acc_disk_normal.x,
                                           acc_disk_normal.y,
                                           acc_disk_normal.z);
  black_hole_shader.set("acc_disk_ref", acc_disk_ref.x,
                                        acc_disk_ref.y,
                                        acc_disk_ref.z);
                                        
  black_hole_shader.set("sky_texture", sky);
  black_hole_shader.set("acc_disk_texture", acc_disk);
  
  black_hole_shader.set("dphi", dphi);
  black_hole_shader.set("NSTEPS", (int) (max_angle / dphi));
  
  black_hole_shader.set("acc_min_u", 1.0 / acc_disk_max_dist);
  black_hole_shader.set("acc_max_u", 1.0 / acc_disk_min_dist);
  
  black_hole_shader.set("ACC_DISK", 0);
  black_hole_shader.set("SKY", 1);
  
  fill(255);
  noStroke();
  background(0);
  shader(black_hole_shader);
  render("anim", 1, false, false);
  rect(0, 0, width, height);
  //resetShader();
}

void draw(){
  //rotating blackhole animation code
  /*
  println(frameCount);
  acc_disk_ref = rotateAboutAxis(acc_disk_normal, acc_disk_ref, 0.001);
  black_hole_shader.set("acc_disk_ref", acc_disk_ref.x,
                                        acc_disk_ref.y,
                                        acc_disk_ref.z);
  if(frameCount < 2){
    render("anim", frameCount, false, false);
  }else{
    background(0);
    shader(black_hole_shader);
    rect(0, 0, width, height);
    noLoop();
  }
  */
}

void render(String dir, int num, boolean sky, boolean bh){
  render_texture = createGraphics(render_width, render_height, P2D);
  
  pp_distance = render_width / tan(FOV);
  n = new PVector(bh_center.x * render_width,
                  bh_center.y * render_height,
                  pp_distance);
                  
  black_hole_shader.set("center", (float) render_width/2, (float) render_height/2);
  black_hole_shader.set("u0", 1.0 / black_hole_distance);
  black_hole_shader.set("n", 0.0, 0.0, 1.0);
  black_hole_shader.set("pp_distance", pp_distance);
  
  if(bh){
    black_hole_shader.set("ACC_DISK", 1);
    black_hole_shader.set("SKY", 0);
    render_texture.beginDraw();
    render_texture.fill(255);
    render_texture.noStroke();
    //render_texture.background(200);
    render_texture.shader(black_hole_shader);
    render_texture.rect(0, 0, render_width, render_height);
    render_texture.save(dir + "/acc_disk/" + str(num) + ".png");
  }
  if(sky){
    black_hole_shader.set("ACC_DISK", 0);
    black_hole_shader.set("SKY", 1);
    render_texture.endDraw();
    render_texture.beginDraw();
    render_texture.fill(255);
    render_texture.noStroke();
    render_texture.background(200);
    render_texture.shader(black_hole_shader);
    render_texture.rect(0, 0, render_width, render_height);
    render_texture.save(dir + "/sky/" + str(num) + ".png");
    render_texture.endDraw();
  }
  if(! (sky || bh)){
    black_hole_shader.set("ACC_DISK", 1);
    black_hole_shader.set("SKY", 1);
    render_texture.beginDraw();
    render_texture.fill(255);
    render_texture.noStroke();
    render_texture.background(200);
    render_texture.shader(black_hole_shader);
    render_texture.rect(0, 0, render_width, render_height);
    render_texture.save(dir + "/together/" + str(num) + ".png");
    render_texture.endDraw();
  }
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
