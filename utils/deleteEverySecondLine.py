with open('converterFile.txt', 'r') as infile, open('shorterfile.txt', 'w') as outfile:
    lines = infile.readlines()
    count = 0
    for i, line in enumerate(lines):
        if i % 2 == 0:
            count += 1
            parts = line.split(':')
            prefix = '{:07d}'.format(count-1)
            outfile.write(prefix + ' : ' + parts[1])