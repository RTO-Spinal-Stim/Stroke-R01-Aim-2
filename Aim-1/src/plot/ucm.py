import pandas as pd
import matplotlib.pyplot as plt

# Load the data
data_path = "Y:\\LabMembers\\MTillman\\SavedOutcomes\\StrokeSpinalStim\\Overground_EMG_Kinematics\\MergedTablesAffectedUnaffected\\matchedCyclesPrePost.csv"
df = pd.read_csv(data_path)
df.head()