// renderer settings
int RENDER_WIDTH = 409;
int RENDER_HEIGHT = 216;
int NUM_FRAMES = 60;
float FOV = 50;
float BLACK_HOLE_PITCH = 3;
float BLACK_HOLE_TILT = 10;
float BLACK_HOLE_DISTANCE = 16;
float ACC_DISK_MIN_DIST = 1.4;
float ACC_DISK_MAX_DIST = 8;
PVector BH_CENTER = new PVector(0, 0);

float dphi = 0.03;
float max_angle = 360;

BlackHoleRenderer preview, render;

void setup(){
  // preview settings
  size(900, 400, P2D);
  preview = new BlackHoleRenderer(
    900,
    400,
    FOV,
    BLACK_HOLE_DISTANCE,
    BH_CENTER.x,
    BH_CENTER.y,
    BLACK_HOLE_PITCH,
    0,
    BLACK_HOLE_TILT,
    max_angle,
    dphi,
    "sky_bg.jpg",
    ACC_DISK_MIN_DIST,
    ACC_DISK_MAX_DIST,
    "acc_disk.png",
    "blackhole.frag",
    null
  );

  render = new BlackHoleRenderer(
    RENDER_WIDTH,
    RENDER_HEIGHT,
    FOV,
    BLACK_HOLE_DISTANCE,
    BH_CENTER.x,
    BH_CENTER.y,
    BLACK_HOLE_PITCH,
    0,
    BLACK_HOLE_TILT,
    max_angle,
    dphi,
    "sky_bg.jpg",
    ACC_DISK_MIN_DIST,
    ACC_DISK_MAX_DIST,
    "acc_disk.png",
    "blackhole.frag",
    "anim"
  );

  preview.renderToDisplay();
  textAlign(CENTER);
  textSize(20);
}

void draw(){
  /*
  // still frames for rotating blackhole animation
  if(frameCount <= NUM_FRAMES){
    render.rotateBHAboutNormal(radians(6));
    render.renderToImage(frameCount, false, false);
    resetShader();
    background(10);
    text("rendering frame: " + str(frameCount), width/2, height/2);
    println(frameCount);
  }else{
    background(10);
    text("render finished", width/2, height/2);
  }
  */
}
