{ mkDerivation, lib, fetchFromGitHub, cmake, boost17x, ceres-solver, eigen,
  flann, freeimage, glog, libGLU, glew, qtbase,
  cudaSupport ? false, cudaPackages }:

assert cudaSupport -> cudaPackages != { };

let
  boost_static = boost17x.override { enableStatic = true; };

  # TODO: migrate to redist packages
  inherit (cudaPackages) cudatoolkit;
in
mkDerivation rec {
  version = "3.8";
  pname = "colmap";
  src = fetchFromGitHub {
     owner = "colmap";
     repo = "colmap";
     rev = version;
     hash = "sha256-1uUbUZdz49TloEaPJijNwa51DxIPjgz/fthnbWLfgS8=";
  };

  # TODO: rm once the gcc11 issue is closed, https://github.com/colmap/colmap/issues/1418#issuecomment-1049305256
  cmakeFlags = [ "-DOPENGL_ENABLED=ON" ] ++ lib.optionals cudaSupport [
    "-DCUDA_ENABLED=ON"
    "-DCMAKE_CUDA_ARCHITECTURES=native"
    "-DCUDA_NVCC_FLAGS=--std=c++14"
  ];

  buildInputs = [
    boost_static ceres-solver eigen flann
    freeimage glog libGLU glew qtbase
  ] ++ lib.optionals cudaSupport [
    cudatoolkit
  ];
  
  patches = [ ./opengl-no-gui.patch ];

  nativeBuildInputs = [
    cmake
  ] ++ lib.optionals cudaSupport [
    cudaPackages.autoAddOpenGLRunpathHook
  ];

  meta = with lib; {
    description = "COLMAP - Structure-From-Motion and Multi-View Stereo pipeline";
    longDescription = ''
       COLMAP is a general-purpose Structure-from-Motion (SfM) and Multi-View Stereo (MVS) pipeline
       with a graphical and command-line interface.
    '';
    homepage = "https://colmap.github.io/index.html";
    license = licenses.bsd3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ lebastr ];
  };
}
