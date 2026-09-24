import sys
import statistics

# Read input from standard input
for line_number, line in enumerate(sys.stdin, start=1):
    # Split the line into columns
    columns = line.strip().split('\t')  # Assuming tab-separated, adjust as needed

    # Extract values from column 5, split by ","
    values_in_column_4 = [float(value) for value in columns[3].split(',')]
    values_in_column_5 = [float(value) for value in columns[4].split(',')]
    # Calculate the median
    median_value_1 = round(statistics.median(values_in_column_4),2)
    median_value_2 = round(statistics.median(values_in_column_5),2)
    # Update the fifth column with the calculated median
    columns[3] = str(median_value_1)
    columns[4] = str(median_value_2)
    # Print all columns
    print('\t'.join(columns))

