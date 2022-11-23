#!/usr/bin/python
import configparser
import os
import sys

import testutils


def generate_connection_string(attrs):
    attrs_str_list = []
    for key, value in attrs:
        # TODO: obfuscate passwords???   if key.lower() in ('password', 'pwd'):
        # escape/bookend values with special characters
        #  ref: https://learn.microsoft.com/en-us/openspecs/sql_server_protocols/ms-odbcstr/348b0b4d-358a-41fb-9753-6351425809cb
        if any(c in value for c in (';', '}', ' ')):
            value = '{{{}}}'.format(value.replace('}', '}}'))

        attrs_str_list.append(f'{key}={value}')

    conn_str = ';'.join(attrs_str_list)
    return conn_str


def read_db_config():
    sqlserver = []
    postgresql = []
    mysql = []

    # get the filename of the database configuration file
    pyodbc_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    default_cfg_file = os.path.join(pyodbc_dir, 'tmp', 'database.cfg')
    cfg_file = os.getenv('PYODBC_DATABASE_CFG', default_cfg_file)

    if os.path.exists(cfg_file):
        print(f'Using database configuration file: {cfg_file}')
        # read the file contents
        config = configparser.ConfigParser()
        config.optionxform = str  # prevents keys from being lowercased
        config.read(cfg_file)

        # generate the connection strings
        for section in config.sections():
            section_lower = section.lower()
            if section_lower.startswith('sqlserver'):
                conn_string = generate_connection_string(config.items(section))
                sqlserver.append(conn_string)
            elif section_lower.startswith('postgres'):
                conn_string = generate_connection_string(config.items(section))
                postgresql.append(conn_string)
            elif section_lower.startswith('mysql'):
                conn_string = generate_connection_string(config.items(section))
                mysql.append(conn_string)
    else:
        print(f'Database configuration file not found: {cfg_file}')

    return sqlserver, postgresql, mysql


def main(sqlserver=None, postgresql=None, mysql=None, verbose=0):

    if not (sqlserver or postgresql or mysql):
        sqlserver, postgresql, mysql = read_db_config()

    if not (sqlserver or postgresql or mysql):
        print('No tests have been run because no database connection info was provided')
        return False

    # there is an assumption here about where this file is located
    pyodbc_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    databases = {
        'SQL Server': {
            'conn_strs': sqlserver or [],
            'discovery_start_dir': os.path.join(pyodbc_dir, 'tests3'),
            'discovery_pattern': 'sqlservertests.py',
        },
        'PostgreSQL': {
            'conn_strs': postgresql or [],
            'discovery_start_dir': os.path.join(pyodbc_dir, 'tests3'),
            'discovery_pattern': 'pgtests.py',
        },
        'MySQL': {
            'conn_strs': mysql or [],
            'discovery_start_dir': os.path.join(pyodbc_dir, 'tests3'),
            'discovery_pattern': 'mysqltests.py',
        },
    }

    overall_result = True
    for db_name, db_attrs in databases.items():

        for db_conn_str in db_attrs['conn_strs']:
            print(f'Running tests against {db_name} with connection string: {db_conn_str}')

            if verbose > 0:
                cnxn = pyodbc.connect(db_conn_str)
                testutils.print_library_info(cnxn)
                cnxn.close()

            # it doesn't seem to be possible to pass test parameters into the test
            # discovery process, so the connection string will have to be passed to
            # the test cases via an environment variable
            os.environ['PYODBC_CONN_STR'] = db_conn_str

            result = testutils.discover_and_run(
                top_level_dir=pyodbc_dir,
                start_dir=db_attrs['discovery_start_dir'],
                pattern=db_attrs['discovery_pattern'],
                verbosity=verbose,
            )
            if not result.wasSuccessful():
                overall_result = False

    return overall_result


if __name__ == '__main__':
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument("--sqlserver", action='append', help="connection string for SQL Server")
    parser.add_argument("--postgresql", action='append', help="connection string for PostgreSQL")
    parser.add_argument("--mysql", action='append', help="connection string for MySQL")
    parser.add_argument("-v", "--verbose", action="count", default=0, help="increment test verbosity (can be used multiple times)")
    args = parser.parse_args()

    # add the build directory to the Python path so we're testing the latest
    # build, not the pip-installed version
    testutils.add_to_path()

    # only after setting the Python path, import the pyodbc module
    import pyodbc

    # run the tests
    passed = main(**vars(args))
    sys.exit(0 if passed else 1)
