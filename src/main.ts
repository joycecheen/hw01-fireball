import {vec3} from 'gl-matrix';
import {vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  'Body Color': [35, 20, 46],
  'Fire Color': [206, 0, 255],
  'Reset Scene': resetScene,
  'Eye Angle': 0.7,
  'Fire Speed': 2,
};

let square: Square;
let fire: Icosphere;
let body: Icosphere;
let prevTesselations: number = 5;

function loadScene() {
  fire = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  fire.create();
  body = new Icosphere(vec3.fromValues(0, 0.09, 0), 1, controls.tesselations);
  body.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
}

function resetScene() {
  controls.tesselations = 5;
  controls['Body Color'] = [35, 20, 46];
  controls['Fire Color'] = [206, 0, 255];
  controls['Eye Angle'] = 0.7;
  controls['Fire Speed'] = 2;
  loadScene();
}

function main() {
  var time = 0;

  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  gui.addColor(controls, 'Body Color');
  gui.addColor(controls, 'Fire Color');
  gui.add(controls, 'Eye Angle', -3.14, 3.14).step(0.01);
  gui.add(controls, 'Fire Speed', 1, 6).step(1);
  gui.add(controls, 'Reset Scene');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.071,0.188,0.298,1);
  gl.enable(gl.DEPTH_TEST);
  gl.enable(gl.BLEND);
  gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

  const fireShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fire-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fire-frag.glsl')),
  ]);
  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);
  const flat = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/flat-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/flat-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    time++;
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      fire = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      fire.create();
      body = new Icosphere(vec3.fromValues(0, 0.09, 0), 1, controls.tesselations);
      body.create();
    }

    gl.disable(gl.DEPTH_TEST);
    flat.setTime(time);
    renderer.render(camera, flat, [
      square,
    ]);
    gl.enable(gl.DEPTH_TEST);

    lambert.setGeometryColor(vec4.fromValues(controls['Body Color'][0] / 255, controls['Body Color'][1] / 255, controls['Body Color'][2] / 255, 1));
    lambert.setEye(controls['Eye Angle']);
    lambert.setTime(time);
    renderer.render(camera, lambert, [
      body,
    ]);

    gl.depthMask(false);
    fireShader.setGeometryColor(vec4.fromValues(controls['Fire Color'][0] / 255, controls['Fire Color'][1] / 255, controls['Fire Color'][2] / 255, 1));
    fireShader.setTime(time);
    fireShader.setSpeed(controls['Fire Speed']);
    renderer.render(camera, fireShader, [
      fire,
    ]);
    gl.depthMask(true);

    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
