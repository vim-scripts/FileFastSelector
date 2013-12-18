import vim
import operator

def longest_substring_size(str1, str2):
	n1 = len(str1)
	n2 = len(str2)
	n2inc = n2 + 1

	L = [0 for i in range((n1 + 1) * n2inc)]

	res = 0
	for i in range(n1):
		for j in range(n2):
			if str1[i] == str2[j]:
				ind = (i + 1) * n2inc + (j + 1)
				L[ind] = L[i * n2inc + j] + 1
				if L[ind] > res:
					res = L[ind]

	return res

def check_symbols_uni(s, symbols):
	prevPos = 0
	for i in symbols:
		pos = s.find(i, prevPos)
		if pos == -1:
			return 0
		else:
			prevPos = pos + 1

	return -longest_substring_size(s, symbols)

def check_symbols_1(s, symbols):
	if s.find(symbols[0]) == -1:
		return 0
	return -1

def check_symbols_2(s, symbols):
	pos = s.find(symbols[0])
	if pos == -1:
		return 0

	if s.rfind(symbols[1]) < pos:
		return 0

	if s.find(symbols) != -1:
		return -2

	return -1

def check_symbols_3(s, symbols):
	p1 = s.find(symbols[0])
	if p1 == -1:
		return 0

	p2 = s.rfind(symbols[2])
	if p2 < p1:
		return 0

	if s[p1 : p2 + 1].find(symbols[1]) == -1:
		return 0

	if s.find(symbols) != -1:
		return -3
	if s.find(symbols[:2]) != -1 or s.find(symbols[1:]) != -1:
		return -2

	return -1

if int(vim.eval("g:FFS_ignore_case")):
	caseMod = str.lower
else:
	caseMod = lambda x: x

smbs = caseMod(vim.eval('str'))
oldSymbols = caseMod(vim.eval('s:user_line'))
if smbs.find(oldSymbols) != -1:
	fileListVar = 's:filtered_file_list'
else:
	fileListVar = 's:file_list'

if len(smbs) != 0:
	nSymbols = len(smbs)
	if nSymbols == 1:
		check_symbols = check_symbols_1
	elif nSymbols == 2:
		check_symbols = check_symbols_2
	elif nSymbols == 3:
		check_symbols = check_symbols_2
	else:
		check_symbols = check_symbols_uni

	fileList = [(check_symbols(x[0], smbs), x) for x in vim.eval(fileListVar)]
	fileList = [x for x in fileList if operator.itemgetter(0)]
	fileList.sort(key=operator.itemgetter(0, 1))

	vim.command("let s:filtered_file_list=[]")
	for fn in fileList:
		vim.command('let s:filtered_file_list+=[["%s","%s"]]' % (fn[1][0].replace('\\', '\\\\'), fn[1][1].replace('\\', '\\\\')))
else:
	vim.command("let s:filtered_file_list = s:file_list")
