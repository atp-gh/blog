// arata — script FFI: dynamically loads and invokes MathJax and Mermaid
// after each post view renders, mirroring apollo's MathJax config + main.js.
//
// Because arata doesn't yet have a custom index.html (Phase 17), the scripts
// are loaded lazily on first use: if MathJax/mermaid are not yet on the page,
// inject the <script> tags, wait for them to load, then call the render API.
// Subsequent calls skip the loading step.
//
// MathJax config matches apollo's: inlineMath [['$','$'], ['\\(','\\)']].
// Mermaid is initialized with theme "dark" or "neutral" based on the current
// effective theme, and re-rendered on theme change (apollo's mermaidRender).

const mathjax_cdn =
  "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js";
const mermaid_cdn =
  "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";

let mermaid_originals = null;

export function typeset_math() {
  if (typeof window === "undefined") return;
  if (window.MathJax && window.MathJax.typesetPromise) {
    window.MathJax.typesetPromise();
    return;
  }
  // Load MathJax lazily.
  if (document.getElementById("MathJax-script")) return;
  window.MathJax = {
    tex: {
      inlineMath: [
        ["$", "$"],
        ["\\(", "\\)"],
      ],
    },
    startup: { typeset: false },
  };
  const script = document.createElement("script");
  script.id = "MathJax-script";
  script.type = "text/javascript";
  script.async = true;
  script.src = mathjax_cdn;
  script.onload = () => {
    if (window.MathJax && window.MathJax.typesetPromise) {
      window.MathJax.typesetPromise();
    }
  };
  document.head.appendChild(script);
}

export function render_mermaid(is_dark) {
  if (typeof window === "undefined") return;

  // Wait until the SPA/Lustre has finished updating the article HTML in the DOM.
  // Two animation frames make this more reliable after route changes or state updates.
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      const blocks = document.getElementsByClassName("mermaid");

      // If there are no Mermaid blocks on the current page, do nothing.
      if (blocks.length === 0) return;

      const originals = [];

      for (let i = 0; i < blocks.length; i++) {
        const block = blocks[i];

        // Mermaid expects the diagram source as plain text.
        // Avoid using innerHTML because it may contain escaped entities.
        const code =
          block.dataset.originalCode ||
          block.textContent ||
          block.innerText ||
          "";

        // Store the original diagram source so it can be restored before re-rendering.
        block.dataset.originalCode = code;
        originals[i] = code;
      }

      import(mermaid_cdn)
        .then((mermaid) => {
          const theme = is_dark ? "dark" : "neutral";

          // Mermaid is rendered manually because the SPA updates content dynamically.
          mermaid.default.initialize({
            startOnLoad: false,
            theme: theme,
          });

          for (let i = 0; i < blocks.length; i++) {
            const block = blocks[i];

            // Allow Mermaid to process the block again after SPA navigation or theme changes.
            delete block.dataset.processed;

            // Restore the raw diagram source as plain text before rendering.
            // This helps avoid issues with escaped HTML entities such as &gt; or &amp;gt;.
            block.textContent = originals[i];
          }

          // Render all Mermaid blocks currently present in the DOM.
          mermaid.default.run();
        })
        .catch((err) => {
          console.error("[arata] mermaid load/render failed", err);
        });
    });
  });
}
