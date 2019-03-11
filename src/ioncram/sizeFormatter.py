import sys

def formatUnit(value):
    units=['KB','MB','GB','TB','PB']
    i=0;
    value=float(value)
    while value >1024.0:
        i+=1
        value/=1024.0
    return "%.2f%s"%(value,units[i])

for l in sys.stdin.readlines():
    print(formatUnit(float(l)))
