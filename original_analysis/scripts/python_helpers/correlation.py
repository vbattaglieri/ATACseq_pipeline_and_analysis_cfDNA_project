import pandas as pd

# Read the file into a DataFrame
file_path = 'HCT116_DKO_overlapping_peaks_median'  # Replace with the actual path to your file
df = pd.read_csv(file_path, sep='\t', header=None, names=['col1', 'col2', 'col3', 'col4', 'col5'])

# Extract values from columns 4 and 5
column4_values = df['col4']
column5_values = df['col5']

# Calculate correlation
correlation = column4_values.corr(column5_values)

# Print the correlation coefficient
print(f'Correlation coefficient between col4 and col5: {correlation}')

