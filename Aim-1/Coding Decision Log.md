# 01-31-2025
## Question:
For calculating muscle synergies, does time normalizing the data affect the outcome?

## Answer:
Nope! The VAFs appear to be the same whether the data is at its original sampling rate or time normalized to 101 points. Deciding to use time normalized because it's more interpretable and matches what's found in the literature.

# 01-28-2025
## Problem: 
Previously in our data analysis, muscle synergies were quantified by combining the L & R muscles into one matrix. There are two issues with this:
1. The L & R muscles' data are extracted from gait cycles that begin and end with the L and R heel strikes, respectively. This means that the L muscles' data may be from 0-100% of a gait cycle (defined L heel strike to L heel strike), and the corresponding R muscles' data would be from 50-150% of that time period. This mismatch is problematic.
2. More typically in the literature, people quantify synergies within each leg individually. So, only the L leg muscles would be examined during a L gait cycle (L heel strike to L heel strike), and only the R leg muscles would be examined during a R gait cycle (R heel strike to R heel strike).

## Solution:
- Short term: After finding literature to support point #2, I will follow the suggestion in point #2 above, isolating each side's leg muscles during its respective gait phase. This is a relatively simple modification of the code.
- Longer term: I will examine what Nicole called a "global" synergy, with both L & R leg muscles, but adjusted so that both sides' muscles are examined within the same time period (i.e. L heel strike to L heel strike). Maybe even looking at both sides combined during L gait cycles AND R gait cycles separately, to examine global synergies during paretic & non-paretic swing/stance phases, etc.
