import pandas as pd

df = pd.read_excel("oasis_cross-sectional.xlsx")

print(df.shape)
print(df.columns.tolist())
print(df.dtypes)
print(df.head(10))
print(df.isna().sum())
