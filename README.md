![https://www.repostatus.org/badges/latest/wip.svg](https://www.repostatus.org/badges/latest/wip.svg)
# Diuca: Glacier physics modelling with the MOOSE framework

Diuca is a [MOOSE](https://mooseframework.inl.gov/) application to
simulate the viscous and elastic deformation of ice in various
conditions.

- [Why Diuca?](#whyDiuca)
- [Installation](#installation)

Diuca currently includes:

- a new Full-Stokes model for viscous ice deformation tested with both Finite Elements (FE) and Finite Volumes (FV). It includes key elements for the modeling of tidewater glaciers such as an ocean boundary condition and a basal sliding law.

- setups for the simulation of elastic ice deformation so far applied to the study of glacier resonance through full response functions and impulse-response experiments.

## Why Diuca?

To follow the MOOSE convention of naming new applications after
animals, Diuca was named after the [White-winged Diuca Finch (Idiopsar
speculifer)](https://www.peruaves.org/thraupidae/white-winged-Diuca-finch-Diuca-speculifera/),
also known as the glacier finch for its unique nesting behavior in
glacier cavities ([Johnson,
1967](https://academic.oup.com/auk/article-abstract/85/3/524/5198113?redirectedFrom=fulltext),
[Hardy & Hardy,
2008](https://bioone.org/journals/The-Wilson-Journal-of-Ornithology/volume-120/issue-3/06-165.1/White-winged-Diuca-Finch-span-classgenus-speciesDiuca-speculifera-span-Nesting/10.1676/06-165.1.short),
[Lazo et al,
2025](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5366418)).

A recent [BBC Earth video](https://youtu.be/lTKsjZN-Aec) reveals for the
first time the life of a family of Diuca finch at Quelccaya Glacier in
Peru.
![Screenshot](https://github.com/wehrad/diuca/blob/PR_flood/assets/BBC_earth_diuca_finch.jpg)

## Installation

Diuca requires a MOOSE installation. To install MOOSE, please follow
the steps described
[here](https://mooseframework.inl.gov/getting_started/installation/conda.html).

Once MOOSE is installed, Diuca can be cloned locally:
```bash
git clone https://github.com/wehrad/Diuca.git
```
Make sure to clone both MOOSE and Diuca in the same `projects/` folder. This makes pointing at MOOSE from Diuca easier.

Then, switch to the main branch:
```bash
cd Diuca
git checkout main
```

Make sure your MOOSE conda environment is activated:
```bash
conda activate moose
```

Compile Diuca (`-j` sets the number of cores to use for compilation):
```bash
make -j 4
```

And run the tests:
```bash
./run_tests -j 4
```

If the installation was successful, you should see that all tests
passing and some skipped. You can now use Diuca to simulate glacier
physics!

To run Diuca on a simple input file, use the newly-created executable:
```bash
./diuca-opt -i inputs/simple_input.i
```

In multiprocessing with `mpiexec`:
```bash
mpiexec -n 6 ./diuca-opt -i inputs/simple_input.i
```
