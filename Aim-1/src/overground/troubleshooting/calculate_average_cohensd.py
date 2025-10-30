import pandas as pd
import numpy as np

def analyze_cohend_data(csv_file):
    """
    Load CSV data and calculate average Cohen's D for each subject,
    then find the overall average of those subject averages.
    """
    
    # Load the CSV file
    df = pd.read_csv(csv_file)
    
    print("Data loaded successfully:")
    print(df.head())
    print(f"\nTotal rows: {len(df)}")
    print(f"Subjects: {df['Subject'].unique()}")
    
    # Calculate average Cohen's D for each subject
    subject_averages = df.groupby('Subject')['CohenD'].mean()
    
    print("\nAverage Cohen's D by Subject:")
    print(subject_averages)
    
    # Calculate the overall average of subject averages
    overall_average = subject_averages.mean()
    
    print(f"\nOverall average of subject averages: {overall_average:.6f}")
    
    return subject_averages, overall_average

# Example usage:
if __name__ == "__main__":
    # Replace 'your_file.csv' with the actual path to your CSV file
    # csv_filename = r"Y:\LabMembers\J_Hunt\SS_Stroke\Per_Feature\Aim1_Paper\SwingDurations_GR_Sym\stat_cohen_d_SwingDurations_GR_Sym.csv"
    # csv_filename = r"Y:\LabMembers\J_Hunt\SS_Stroke\Per_Feature\Aim1_Paper\StepLengths_GR_Sym\stat_cohen_d_StepLengths_GR_Sym.csv"
    csv_filename = r"Y:\LabMembers\J_Hunt\SS_Stroke\Per_Feature\Aim1_Paper\CGAM\stat_cohen_d_CGAM.csv"
    
    try:
        subject_avgs, overall_avg = analyze_cohend_data(csv_filename)
        
        # Additional statistics
        print(f"\nAdditional Statistics:")
        print(f"Number of subjects: {len(subject_avgs)}")
        print(f"Standard deviation of subject averages: {subject_avgs.std():.6f}")
        print(f"Range of subject averages: {subject_avgs.min():.6f} to {subject_avgs.max():.6f}")
        
    except FileNotFoundError:
        print(f"Error: Could not find file '{csv_filename}'")
        print("Please make sure the file exists and the path is correct.")
    except Exception as e:
        print(f"An error occurred: {e}")