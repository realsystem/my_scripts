res = []
with open('fuel.pem', 'r') as t_file:
    line = t_file.readline()
    if line:
        res.append(line.strip())
    while line:
        line = t_file.readline()
        if line:
            res.append(line.strip())
print('\\n'.join(res))
