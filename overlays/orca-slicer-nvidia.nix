final: prev: {
  orca-slicer = prev.symlinkJoin {
    name = "orca-slicer-wrapped";
    paths = [prev.orca-slicer];
    buildInputs = [prev.makeWrapper];
    postBuild = ''
      rm $out/bin/orca-slicer
      makeWrapper ${prev.orca-slicer}/bin/orca-slicer $out/bin/orca-slicer \
        --set __GLX_VENDOR_LIBRARY_NAME mesa \
        --set __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json \
        --set MESA_LOADER_DRIVER_OVERRIDE zink \
        --set GALLIUM_DRIVER zink \
        --set WEBKIT_DISABLE_DMABUF_RENDERER 1
    '';
  };
}
