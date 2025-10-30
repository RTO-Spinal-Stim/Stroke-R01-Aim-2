import pandas as pd

def curr_col_data(df: pd.DataFrame, col: str, factor_column_names: list[str]) -> pd.DataFrame:
    """Isolate the current column name of interest along with the factor columns."""
    return df[[col] + factor_column_names]