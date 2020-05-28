import pyodbc

cnxn = pyodbc.connect("DRIVER={PostgreSQL Unicode};SERVER=localhost;UID=postgres;DATABASE=test", autocommit=True)
cnxn.setdecoding(pyodbc.SQL_WCHAR, encoding='utf-8')
cnxn.setencoding(encoding='utf-8')

cnxn.maxwrite = 1024 * 1024 * 1024

crsr = cnxn.cursor()

crsr.execute("DROP TABLE IF EXISTS t1")
crsr.execute("CREATE TABLE t1(id int, s1 varchar(100), s2 varchar(100))")

v = "x \U0001F31C z"
v2 = '我的'
crsr.execute(r"insert into t1 values (1, U&'x \+01F31C z', '{}')".format(v))
crsr.execute(r"insert into t1 values (2, U&'\6211\7684', '{}')".format(v))

rows = crsr.execute("select * from t1 order by id").fetchall()
for row in rows:
    print('row:', row)

print(v == rows[0][0])
print(v == rows[0][1])
print(v2 == rows[1][0])
print(v2 == rows[1][1])

crsr.close()
cnxn.close()
