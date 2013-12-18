from os import walk
try:
	from os import getcwdu
except ImportError:
	# as python 3 doesn't have getcwdu
	from os import getcwd
	getcwdu = getcwd
from os.path import join, isfile, abspath, split
from fnmatch import fnmatch

import sys

import vim

if int(vim.eval("g:FFS_ignore_case")):
	# don't replace by str.lower as on some builds you will get unicode strings
	caseMod = lambda x: x.lower()
else:
	caseMod = lambda x: x

def find_tags(path):
	p = abspath(path)

	# need to remove last / for right splitting
	if p[-1] == '/' or p[-1] == '\\':
		p = path[:-1]
	
	while not isfile(join(p, 'tags')):
		p, h = split(p)
		if p == '' or h == '':
			return None

	return p

def scan_dir(path, ignoreList):
	ignoreList = [caseMod(x) for x in ignoreList]
	def in_ignore_list(f):
		for i in ignoreList:
			if fnmatch(caseMod(f), i):
				return True

		return False

	res = []
	for root, dirs, files in walk(path):
		res.extend([join(root, f) for f in files if not in_ignore_list(f)])

		toRemove = [x for x in dirs if in_ignore_list(x)]
		for j in toRemove:
			dirs.remove(j)

	n = len(path)
	res = [(caseMod(x[n:]), x) for x in res]

	return res

wd = getcwdu()
rootPath = find_tags(wd)
if rootPath == None:
	rootPath = wd
	
fileList = scan_dir(rootPath, vim.eval("g:FFS_ignore_list"))

if sys.version_info[0] < 3:
	fileList = [(fn[0].encode('utf-8'), fn[1].encode('utf-8')) for fn in fileList]
	rootPath = rootPath.encode('utf-8')

vim.command('let s:base_path_length=%d' % len(rootPath))
vim.command('let s:file_list=[]')
for fn in fileList:
	vim.command('let s:file_list+=[["%s","%s"]]' % (fn[0].replace('\\', '\\\\'), (fn[1].replace('\\', '\\\\'))))

