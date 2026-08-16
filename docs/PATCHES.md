# Termux llama.cpp Patches

llama.cpp Vulkan build in Termux needs three patches at the pinned commit
`650913862` (2026-08-13). Apply after cloning; re-apply after fresh clone.

1. `ggml/src/ggml-vulkan/CMakeLists.txt`
   - Delete the `test_shader_extension_support(...)` block for
     `GL_NV_cooperative_matrix2` (approx lines 74-81). It probes an extension
     Termux glslc cannot compile.
2. `ggml/src/ggml-vulkan/vulkan-shaders/flash_attn_cm2.comp`
   - Move to `flash_attn_cm2.comp.disabled` (uses capability 5447, which
     Termux spirv-opt cannot optimize).
3. `ggml/src/ggml-vulkan/vulkan-shaders/vulkan-shaders-gen.cpp`
   - Comment out `cmd.push_back("-O");` (line ~352). Termux spirv-opt fails on
     newer SPIR-V capabilities (4229/5447: "Invalid capability operand"). All
     shaders still generate; Maven models (Q4_K_M) never use the FP4/coopmat2
     kernels, so unoptimized variants are safe.

Why: Termux `shaderc 2026.3` / `spirv-tools 1.4.357.0` cannot optimize these
newer shader capabilities. No package upgrade path exists at this time.
