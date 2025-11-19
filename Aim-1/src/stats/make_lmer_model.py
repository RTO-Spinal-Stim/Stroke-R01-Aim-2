import pandas as pd
import statsmodels.api as sm
import statsmodels.formula.api as smf

def make_lmer_model(df: pd.DataFrame, 
                    fixed_effect_formula: str, 
                    random_effect_factor: str,
                    random_effect_formula: str,
                    variance_components_formula: dict) -> sm.regression.linear_model.RegressionResultsWrapper:
    """Make a linear mixed effects model using statsmodels."""
    if variance_components_formula is not None:
        model = smf.mixedlm(
            fixed_effect_formula, 
            df, 
            groups=df[random_effect_factor],
            re_formula=random_effect_formula,
            vc_formula=variance_components_formula
        )
    else:
        model = smf.mixedlm(
            fixed_effect_formula, 
            df, 
            groups=df[random_effect_factor],
            re_formula=random_effect_formula
        )
    result = model.fit(reml=True)
    print(result.summary())
    return result
