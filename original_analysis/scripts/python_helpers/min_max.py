import sys

# Read lines from standard input, calculate min and max for columns 2 to 5, and print the results
for line_number, line in enumerate(sys.stdin, start=1):
    # Split the line into columns
    columns = line.strip().split('\t')  # Assuming tab-separated, adjust as needed

    # Extract values from columns 2 to 5
    values_to_process = list(map(float, columns[1:5]))

    # Calculate the min and max values
    min_value = min(values_to_process)
    max_value = max(values_to_process)

    # Print the desired output
    print(f"{columns[0]}\t{min_value}\t{max_value}\t{columns[5]}\t{columns[6]}\t{columns[7]}\t{columns[8]}")

