#! /usr/bin/env python3
import sys
#from itertools import zip
from collections import defaultdict
def help():
    print("python compare_sam_unaligned.py <sam file1 > <sam file 2> ")

if sys.argv[1]=='--h':
    help()
    exit(0)

errorLines=0
def print_error(string):
    global errorLines
    errorLines+=1
    if errorLines==100:
        print("maximum error lines reached")
        exit(0)
    print(string)


input_1=open(sys.argv[1])
input_2=open(sys.argv[2])

specific_tags=sys.argv[3:]

input_dict1={}
#input_dict1=defaultdict(lambda:"EMPTY",input_dict1)


input_dict2={}
#input_dict2=defaultdict(lambda:"EMPTY",input_dict2)

count=0
for l1,l2 in zip(input_1,input_2):
    l1=l1.strip().split("\t")
    l2=l2.strip().split("\t")
    count+=1
    #don't compare cigar string for unmapped reads
#    if  int(l1[1]) &4:
#        l1[4]='unaligned MAQ'
#        l2[4]='unaligned MAQ'
#        l1[5]='unaligned cigar'
#        l2[5]='unaligned cigar'

    f1=l1[:11]
    f2=l2[:11]
    if f1 !=f2:
        print_error("Difference Found in the main line %d"%(count))
        print_error("\t".join(l1))
        print_error("\t".join(l2))
#        exit(0)
    input_dict1={}
    input_dict2={}
    for k in l1[11:]:
        input_dict1[k[:k.index(":")]]=k
    for k in l2[11:]:
        input_dict2[k[:k.index(":")]]=k


    tags=specific_tags
    if specific_tags ==[]:
        tags=set(list(input_dict1.keys())+list(input_dict2.keys()))

    for t in tags:
        if t not in input_dict1:
            input_dict1[t]='EMPTY'
        if t not in input_dict2:
            input_dict2[t]='EMPTY'

    f1=[input_dict1[x] for x in tags]
    f2=[input_dict2[x] for x in tags]

    if f1 != f2:
        diff=filter(lambda x:input_dict1[x]!=input_dict2[x],tags)
        diff=map(lambda x:x+": "+input_dict1[x]+" -> "+input_dict2[x],diff)
        print_error("\t".join(diff))
#        print_error "\t".join(l1)
#        print_error "\t".join(l2)
#        print_error "################################"
#        exit(0)


for l1 in input_1:
    print_error("Extra alignments in input1: %s"%(l1))

for l2 in input_2:
    print_error("Extra alignments in input2: %s"%(l2))
    

