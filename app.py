"""
print ("hello,word")
"""
#print ('goodbye word')
#print ('hello 毛银露')

#整型
#print (0b100)
#print (0o100)
#print (100)
#print (0x100)

#浮点型
#print (123.456)
#print (1.23456e2)

#变量练习
"""
a=45
b=12
print(a,b)
print('a b')
print(a+b)
print(a-b)
print(a*b)
print(a/b)
"""


#使用type函数检查变量类型
"""
a=100
b=123.45
c='hell word'
d=True
print(type(a))
print(type(b))
print(type(c))
print(type(d))
"""

"""
file=open('致橡树.txt','r',encoding='utf-8')
print(file.read())
file.close()
"""


file = open('致橡树.txt', 'r', encoding='utf-8')
for line in file:
    print(line, end='')
file.close()

file = open('致橡树.txt', 'r', encoding='utf-8')
lines = file.readlines()
for line in lines:
    print(line, end='')
file.close()