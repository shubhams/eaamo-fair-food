# Fair Decision-Making for Food Inspections

This repository contains the code used to conduct the analysis in the paper
["Fair Decision-Making for Food
Inspections"](https://dl.acm.org/doi/10.1145/3551624.3555289) by Singh et al.
(EAAMO, 2022). The code uses both `R` and `Python` for the analysis. 

## Original City of Chicago Code
The code used by City of Chicago conducted Schenk Jr. et al. is located in the
`Original-City-Repo` directory, which is a snapshot of the live repo
[here](https://github.com/Chicago/food-inspections-evaluation). Please see the
[README.md](./Original-City-Repo/README.md) inside `Original-City-Repo` that
explains the structure, requirements, and how to run the code.

## Creating Schedules Using Model Scores

We include [ANALYSIS.md](./Original-City-Repo/README.md) that goes over the `R`
files that are used to create new models (Section 4) and that change how the
model scores are used (Section 5).

## Data & Analysis
The output from the `R` files is compiled using Google Sheets and the exported
CSV are provided inside the `analyses` directory. Use the Python notebook
`plot_better.ipynb` to generate the plots used in the paper.

### Python Requirements
+ Python >= `3.10`
+ `jupyter`
+ `matplotlib`
+ `numpy`
+ `pandas`
+ `seaborn`
+ `scipy`

## Citation
Use the following `BibTex`:
```bibtex
@inproceedings{singhFood2022,
    author = {Singh, Shubham and Shah, Bhuvni and Kanich, Chris and Kash, Ian A.},
    title = {Fair Decision-Making for Food Inspections},
    year = {2022},
    isbn = {9781450394772},
    publisher = {Association for Computing Machinery},
    address = {New York, NY, USA},
    url = {https://doi.org/10.1145/3551624.3555289},
    doi = {10.1145/3551624.3555289},
    booktitle = {Proceedings of the 2nd ACM Conference on Equity and Access in Algorithms, Mechanisms, and Optimization},
    articleno = {5},
    numpages = {11},
    keywords = {scheduling, food inspections, fairness},
    location = {Arlington, VA, USA},
    series = {EAAMO '22}
}
```

DOI: https://doi.org/10.1145/3551624.35552