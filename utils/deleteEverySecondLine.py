with open('converterFile.txt', 'r') as infile, open('shorterFile.txt', 'w') as outfile:
    lines = infile.readlines()
    for i, line in enumerate(lines):
        if i % 2 == 0:
            outfile.write(line)