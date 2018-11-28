import re

def atoi(text):
    return int(text) if text.isdigit() else text

def natural_keys(text):
    '''
    alist.sort(key=natural_keys) sorts in human order
    http://nedbatchelder.com/blog/200712/human_sorting.html
    (See Toothy's implementation in the comments)
    '''
    return [ atoi(c) for c in re.split('(\d+)', text) ]

filename = "frames.txt"
file = open(filename, "r")

alist=file.readlines()
file.close()

alist.sort(key=natural_keys)

filename1 = "frames1.txt"
file1 = open(filename1, "w")
file1.writelines(alist)
file1.close()
