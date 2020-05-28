import pyodbc

cnxn = pyodbc.connect("DRIVER={PostgreSQL Unicode};SERVER=localhost;UID=postgres;DATABASE=test", autocommit=True)
cnxn.setdecoding(pyodbc.SQL_WCHAR, encoding='utf-8')
cnxn.setencoding(encoding='utf-8')

cnxn.maxwrite = 1024 * 1024 * 1024

crsr = cnxn.cursor()

crsr.execute("DROP TABLE IF EXISTS t1")
crsr.execute("CREATE TABLE t1(s1 varchar(100), s2 varchar(100))")

v = "x \U0001F31C z"
crsr.execute(r"insert into t1 values (U&'x \+01F31C z', '{}')".format(v))

rows = crsr.execute("select s from t1").fetchall()
for row in rows:
    print('row:', row)

print(v == rows[0][0])
print(v == rows[0][1])

crsr.close()
cnxn.close()
