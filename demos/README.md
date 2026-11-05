# Computing Virtual Labs · Lectures 27–31

Five standalone, dependency-free, responsive teaching simulations.

## Quick start

Serve this folder from any static HTTP server (recommended because it uses a JavaScript module):

```sh
cd demos
python -m http.server 8000
```

Visit `http://localhost:8000/?lecture=27` (or 28, 29, 30, 31). Use the dropdown to switch lessons. Your local server may also serve `/index.html?lecture=30`.

## Quarto integration

This folder lives at `demos/` and is published through `project: resources:` (`- demos/`) in `_quarto.yml`. Lecture slides link to `../demos/index.html?lecture=27` (change `27` to 28–31 for other lessons). The Back to lecture link in `app.js` targets `../lectures/lecture-NN.html`.

## Files

- `index.html` — semantic shell, lecture switcher, controls/results slots and experiment notes
- `styles.css` — responsive visual layout
- `app.js` — shared code plus five separate lab modules

No libraries, CDNs, backend, or private data collection required. Export notes locally through the browser.

## Scientific and educational limitations

- Grid computing: deterministic cooperative scheduler, not a real grid middleware; failures requeue uncollected work.
- Green computing: editable assumptions, not measured energy or verified local emissions factors; off time assumed zero watts.
- Big data: small deterministic dataset to expose MapReduce transformations, not Hadoop or throughput benchmarks.
- Quantum computing: real-amplitude two-qubit state vector, no imaginary phases or quantum hardware noise.
- BCI: invented motor-intent sensor values and a scalar decoder, not real EEG or medical functionality.
