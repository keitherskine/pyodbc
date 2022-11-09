#!/usr/bin/env python

import sys, os, re, shlex
from os.path import exists, abspath, dirname, join, isdir, relpath, expanduser

try:
    # Allow use of setuptools so eggs can be built.
    from setuptools import setup, Command
except ImportError:
    from distutils.core import setup, Command

from distutils.extension import Extension
from distutils.errors import *

if sys.hexversion >= 0x03000000:
    from configparser import ConfigParser
else:
    from ConfigParser import ConfigParser


# This version identifier should refer to the NEXT release version.
# AFTER each release, this version should be incremented.
VERSION = '4.0.35'


def _print(s):
    # Python 2/3 compatibility
    sys.stdout.write(s + '\n')


class VersionCommand(Command):

    description = "prints the pyodbc version, determined from git"

    user_options = []

    def initialize_options(self):
        self.verbose = 0

    def finalize_options(self):
        pass

    def run(self):
        version_str = get_version()
        sys.stdout.write(version_str + '\n')


class TagsCommand(Command):

    description = 'runs etags'

    user_options = []

    def initialize_options(self):
        pass

    def finalize_options(self):
        pass

    def run(self):
        # Windows versions of etag do not seem to expand wildcards (which Unix shells normally do for Unix utilities),
        # so find all of the files ourselves.
        files = [ join('src', f) for f in os.listdir('src') if f.endswith(('.h', '.cpp')) ]
        cmd = 'etags %s' % ' '.join(files)
        return os.system(cmd)



def main():

    version_str = get_version()

    with open(join(dirname(abspath(__file__)), 'README.md')) as f:
        long_description = f.read()

    settings = get_compiler_settings(version_str)

    files = [ relpath(join('src', f)) for f in os.listdir('src') if f.endswith('.cpp') ]

    if exists('MANIFEST'):
        os.remove('MANIFEST')

    kwargs = {
        'name': "pyodbc",
        'version': version_str,
        'description': "DB API Module for ODBC",

        'long_description': long_description,
        'long_description_content_type': 'text/markdown',

        'maintainer':       "Michael Kleehammer",
        'maintainer_email': "michael@kleehammer.com",

        'ext_modules': [Extension('pyodbc', sorted(files), **settings)],

        'data_files': [
            ('', ['src/pyodbc.pyi'])  # places pyodbc.pyi alongside pyodbc.py in site-packages
        ],

        'license': 'MIT',

        'python_requires': '>=2.7, !=3.0.*, !=3.1.*, !=3.2.*, !=3.3.*, !=3.4.*, !=3.5.*',

        'classifiers': ['Development Status :: 5 - Production/Stable',
                       'Intended Audience :: Developers',
                       'Intended Audience :: System Administrators',
                       'License :: OSI Approved :: MIT License',
                       'Operating System :: Microsoft :: Windows',
                       'Operating System :: POSIX',
                       'Programming Language :: Python',
                       'Programming Language :: Python :: 2',
                       'Programming Language :: Python :: 2.7',
                       'Programming Language :: Python :: 3',
                       'Programming Language :: Python :: 3.6',
                       'Programming Language :: Python :: 3.7',
                       'Programming Language :: Python :: 3.8',
                       'Programming Language :: Python :: 3.9',
                       'Programming Language :: Python :: 3.10',
                       'Programming Language :: Python :: 3.11',
                       'Topic :: Database',
                       ],

        'url': 'https://github.com/mkleehammer/pyodbc',
        'cmdclass': { 'version' : VersionCommand,
                     'tags'    : TagsCommand }
        }

    if sys.hexversion >= 0x02060000:
        kwargs['options'] = {
            'bdist_wininst': {'user_access_control' : 'auto'}
            }

    setup(**kwargs)


def get_compiler_settings(version_str):

    settings = {
        'extra_compile_args' : [],
        'extra_link_args': [],
        'libraries': [],
        'include_dirs': [],
        'define_macros' : [ ('PYODBC_VERSION', version_str) ]
    }

    # This isn't the best or right way to do this, but I don't see how someone is supposed to sanely subclass the build
    # command.
    for option in ['assert', 'trace', 'leak-check']:
        try:
            sys.argv.remove('--%s' % option)
            settings['define_macros'].append(('PYODBC_%s' % option.replace('-', '_').upper(), 1))
        except ValueError:
            pass

    if os.name == 'nt':
        settings['extra_compile_args'].extend([
            '/Wall',
            '/wd4514',          # unreference inline function removed
            '/wd4820',          # padding after struct member
            '/wd4668',          # is not defined as a preprocessor macro
            '/wd4711', # function selected for automatic inline expansion
            '/wd4100', # unreferenced formal parameter
            '/wd4127', # "conditional expression is constant" testing compilation constants
            '/wd4191', # casts to PYCFunction which doesn't have the keywords parameter
        ])

        if '--windbg' in sys.argv:
            # Used only temporarily to add some debugging flags to get better stack traces in
            # the debugger.  This is not related to building debug versions of Python which use
            # "--debug".
            sys.argv.remove('--windbg')
            settings['extra_compile_args'].extend('/Od /Ge /GS /GZ /RTC1 /Wp64 /Yd'.split())

        # Visual Studio 2019 defaults to using __CxxFrameHandler4 which is in
        # VCRUNTIME140_1.DLL which Python 3.7 and earlier are not linked to.  This requirement
        # means pyodbc will not load unless the user has installed a UCRT update.  Turn this
        # off to match the Python 3.7 settings.
        #
        # Unfortunately these are *hidden* settings.  I guess we should be glad they actually
        # made the settings.
        # https://lectem.github.io/msvc/reverse-engineering/build/2019/01/21/MSVC-hidden-flags.html

        if sys.hexversion >= 0x03050000:
            settings['extra_compile_args'].append('/d2FH4-')
            settings['extra_link_args'].append('/d2:-FH4-')

        settings['libraries'].append('odbc32')
        settings['libraries'].append('advapi32')

    elif os.environ.get("OS", '').lower().startswith('windows'):
        # Windows Cygwin (posix on windows)
        # OS name not windows, but still on Windows
        settings['libraries'].append('odbc32')

    elif sys.platform == 'darwin':
        # Python functions take a lot of 'char *' that really should be const.  gcc complains about this *a lot*
        settings['extra_compile_args'].extend([
            '-Wno-write-strings',
            '-Wno-deprecated-declarations'
        ])

        # Homebrew installs odbc_config
        pipe = os.popen('odbc_config --cflags --libs 2>/dev/null')
        cflags, ldflags = pipe.readlines()
        exit_status = pipe.close()

        if exit_status is None:
            settings['extra_compile_args'].extend(shlex.split(cflags))
            settings['extra_link_args'].extend(shlex.split(ldflags))
        else:
            settings['libraries'].append('odbc')
            # Add directories for MacPorts and Homebrew.
            dirs = [
                '/usr/local/include',
                '/opt/local/include',
                '/opt/homebrew/include',
                expanduser('~/homebrew/include'),
            ]
            settings['include_dirs'].extend(dir for dir in dirs if isdir(dir))
            # unixODBC make/install places libodbc.dylib in /usr/local/lib/ by default
            # ( also OS/X since El Capitan prevents /usr/lib from being accessed )
            settings['library_dirs'] = ['/usr/local/lib', '/opt/homebrew/lib']
    else:
        # Other posix-like: Linux, Solaris, etc.

        # Python functions take a lot of 'char *' that really should be const.  gcc complains about this *a lot*
        settings['extra_compile_args'].append('-Wno-write-strings')

        cflags = os.popen('odbc_config --cflags 2>/dev/null').read().strip()
        if cflags:
            settings['extra_compile_args'].extend(cflags.split())
        ldflags = os.popen('odbc_config --libs 2>/dev/null').read().strip()
        if ldflags:
            settings['extra_link_args'].extend(ldflags.split())

        from array import array
        UNICODE_WIDTH = array('u').itemsize
#        if UNICODE_WIDTH == 4:
#            # This makes UnixODBC use UCS-4 instead of UCS-2, which works better with sizeof(wchar_t)==4.
#            # Thanks to Marc-Antoine Parent
#            settings['define_macros'].append(('SQL_WCHART_CONVERT', '1'))

        # What is the proper way to detect iODBC, MyODBC, unixODBC, etc.?
        settings['libraries'].append('odbc')

    return settings


def get_version():
    """
    Returns the version of the product as (description, [major,minor,micro,beta]).

    If the release is official, `beta` will be 9999 (OFFICIAL_BUILD).

      1. If in a git repository, use the latest tag (git describe).
      2. If in an unzipped source directory (from setup.py sdist),
         read the version from the PKG-INFO file.
      3. Use 4.0.0.dev0 and complain a lot.
    """
    v_major, v_minor, v_micro = VERSION.split(".")

    rc, result = getoutput("git describe --tags --always --match [0-9]*")
    if rc != 0:
        # we are not in a git repo at all, possibly in a downloaded zip file, hence
        # this will be marked as a dev version of the new release
        print('KME: rc=0')  # temp!!!!
        return f'{v_major}.{v_minor}.dev{v_micro}'

    match = re.match(r"^(\d+).(\d+).(\d+)-(\d+)-g[0-9a-z]+$", result)
    if match is None:
        # we are in a git repo but the tag cannot be found or cannot be parsed, in
        # which case we are probably in Git Actions (bear in mind Github Actions fetches
        # repos with the --no-tags, so we can't figure out the release version from the
        # tags), hence use the new version
        print('KME: match is None')  # temp!!!!
        return f'{v_major}.{v_minor}.{v_micro}'

    g_major, g_minor, g_micro, g_num_commits = match.groups()
    if g_num_commits == '0':
        # we are in a repo and the current commit is the latest tag, so set the
        # version as the tag
        print('KME: match is not None, commits=0')  # temp!!!!
        return f'{g_major}.{g_minor}.{g_micro}'
    else:
        # we are in a repo but currently ahead of the latest tag, hence set the
        # version as the tag plus the number of commits
        print('KME: match is not None, commits>0')  # temp!!!!
        return f'{g_major}.{g_minor}.{g_micro}b{g_num_commits}'


def getoutput(cmd):
    pipe = os.popen(cmd, 'r')
    text   = pipe.read().rstrip('\n')
    status = pipe.close() or 0
    return status, text

if __name__ == '__main__':
    main()
