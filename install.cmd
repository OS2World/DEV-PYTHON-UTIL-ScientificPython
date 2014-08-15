extproc python -x

# Copyright 2001 by Andrew I MacIntyre.
# All Rights Reserved.

# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose and without fee is hereby granted,
# provided that the above copyright notice appears in all copies and that
# both that copyright notice and this permission notice appear in
# supporting documentation.

# THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
# INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, INDIRECT OR
# CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF
# USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

# this script is intended only for use on OS/2 systems (hence the 
# .cmd extension, and the above line).  Note however that there are 
# limitations - the script must be started from the directory it lives in
# (the "extproc" command appears not to pass directory information to 
#  Python when attempting to start the script using a path name :-( )

# This is an installation script for prebuilt binary Python extensions/packages
#
# Using the Python interpreter to manage the installation achieves
# several things:
# - makes sure we have a working Python
# - simplifies figuring out where to put things, as the Python
#   interpreter already knows where many things should be
#
# Information not known to the Python interpreter are extracted from a
# file called 'install.cnf' in the same directory as this script
#
# This script expects to find UNZIP.EXE on the path, and assumes what 
# it is about to install is to be unpacked in $PYTHONHOME/Lib/site-packages.

import sys, os, string

# read the configuration settings
config = { 'pkg_name': None,
	   'pkg_version': None,
	   'pkg_description': None,
	   'test_file_exists': [],
	   'test_file_not_exists': [] }
try:
	cfgfile = open('install.cnf', 'r')
except:
	print 'Could not open the configuration file "install.dat". Installation aborted.'
	sys.exit(1)
while 1:
	line = cfgfile.readline()
	if not line:
		break

	# skip comments and blank lines
	if line[:1] in '#;':
		continue
	if len(string.strip(line)) == 0:
		continue

	# record the option settings
	opt, value = string.split(line, '=', 1)
	opt = string.lower(string.strip(opt))
	value = string.strip(value)
	if config.has_key(opt):
		if opt[:5] == 'test_':
			config[opt].append(value)
		else:
			config[opt] = value
cfgfile.close()

# check that we have the package we're going to try and install...
if not (config['pkg_name'] and config['pkg_version']):
	print 'Package information incomplete. Installation aborted.'
	sys.exit(1)
pkg_archive = '%s-%s.zip' % (config['pkg_name'], config['pkg_version'])
try:
	test = open(pkg_archive, 'r')
except IOError:
	print 'Could not open package archive "%s". Installation aborted.' % pkg_archive
	sys.exit(1)
test.close()			# need to do this to avoid sharing violations

# do the specified checks
for file in config['test_file_exists']:
	f = file[:]
	for subst in ('$PYTHONHOME', '${PYTHONHOME}', '%PYTHONHOME%'):
		f = string.replace(f, subst, sys.prefix)
	cnt_exist = 0
	try:
		test = open(os.path.normpath(f), 'r')
	except IOError:
		cnt_exist = cnt_exist + 1
		print 'required file "%s" cannot be found' % file
	else:
		test.close()
for file in config['test_file_not_exists']:
	f = file[:]
	for subst in ('$PYTHONHOME', '${PYTHONHOME}', '%PYTHONHOME%'):
		f = string.replace(f, subst, sys.prefix)
	cnt_nexist = 0
	try:	
		test = open(os.path.normpath(f), 'r')
	except IOError:
		pass			# desired result
	else:
		cnt_nexist = cnt_nexist + 1
		print 'file "%s" found when not wanted' % file
		test.close()

if cnt_exist > 0 or cnt_nexist > 0:
	print 'File presence/absence checks failed. Installation aborted.'
	sys.exit(1)

# OK, we got past that, so now lets see if we can actually do the install
pkg = os.path.abspath(pkg_archive)
os.chdir(sys.prefix)
status = os.system('unzip %s' % pkg)
if status > 0:
	print 'UnZip failed with status code %d' % status
	sys.exit(1)
