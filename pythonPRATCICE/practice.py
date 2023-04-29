# Open the text file containing the binary strings for reading
with open("practicetext.txt", "r") as f:
    # Read the contents of the file into a list of strings
    binary_strings = f.readlines()

# Iterate over each binary string in the list
for i in range(len(binary_strings)):
    # Split the string into two parts, the first containing the leading 8 bits and the second containing the remaining bits
    parts = binary_strings[i].strip().split(" : ")
    
    # Get the binary string representing the second part
    second_part = parts[1]

    # Initialize an empty string to hold the modified binary string
    new_second_part = ""

    # Iterate over every second portion of 4 bits in the original string and append the first 4 bits to the new string
    for j in range(0, len(second_part), 8):
        new_second_part += second_part[j:j+4]

    # Combine the leading 8 bits and the modified second part to get the new binary string
    new_binary_string = parts[0] + " : " + new_second_part

    # Replace the original binary string with the modified binary string in the list
    binary_strings[i] = new_binary_string

# Print the modified list of binary strings
print(binary_strings)