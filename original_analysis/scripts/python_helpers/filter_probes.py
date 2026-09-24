import pandas as pd

# Read data from input file
file_path = 'input.txt'  # Change this to the path of your input file
df = pd.read_csv(file_path, sep='\t', header=None, names=['Column1', 'Column2'])

# Group by Column1 and aggregate Column2 values into lists
grouped = df.groupby('Column1')['Column2'].agg(list)

# Filter groups where all values are less than 0.2 or greater than 0.8
filtered_groups = grouped[grouped.apply(lambda x: all(val < 0.2 or val > 0.8 for val in x))]

# Function to determine label based on conditions
def determine_label(values):
    if all(val < 0.2 for val in values):
        return 'low'
    elif all(val > 0.8 for val in values):
        return 'high'
    else:
        return 'mixed'

# Add label column based on conditions
filtered_groups['Label'] = filtered_groups.apply(determine_label)

# Write the filtered groups to an output file
output_file_path = 'output.txt'  # Change this to the desired output file path
filtered_groups.to_csv(output_file_path, sep='\t', header=False)


